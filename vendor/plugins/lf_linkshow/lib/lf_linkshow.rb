# LfLinkshow
require 'fileutils'
require 'ftools'
require 'php_serialize'
require 'net/http'

module LFLinkShow
  class LFClient
    @@lc_version           = '0.3.8'
    @@lc_verbose           = false
    @@lc_charset           = 'DEFAULT'
    @@lc_use_ssl           = false
    @@lc_server            = 'db.linkfeed.ru'
    @@lc_cache_lifetime    = 3600
    @@lc_cache_reloadtime  = 0
    @@lc_links_db_file     = ''
    @@lc_links             = Array.new
    @@lc_links_page        = Array.new
    @@lc_links_delimiter   = ''
    @@lc_error             = ''
    @@lc_host              = ''
    @@lc_request_uri       = ''
    @@lc_fetch_remote_type = ''
    @@lc_socket_timeout    = 6
    @@lc_force_show_code   = false
    @@lc_multi_site        = false
    @@lc_is_static         = false
    @@LINKFEED_USER = ''
    @@request = nil;

    def initialize lfuser, request, options = nil
        host = ''
        @@LINKFEED_USER=lfuser
        @@request=request        
        if options.is_a?(Array)
            if options[:host]
                host = options[:host]
            end
        else
            if options && options.size!=0
            host = options
            options = Array.new
            else
            options = Array.new
            end
        end

        if host.size != 0
            @@lc_host = host
        else
            @@lc_host = @@request.host
        end

        @@lc_host.gsub!(/^https?:\/\//i, '')
        @@lc_host.gsub!(/^www\./i, '')
        @@lc_host = @@lc_host.downcase

        if options.include?(:is_static)&&options[:is_static] 
            @@lc_is_static = true;
        end

        if options.include?(:request_uri) && options[:request_uri].size != 0
            @@lc_request_uri = options[:request_uri];
         else
            if @@lc_is_static
                @@lc_request_uri= @@request.request_uri.gsub(/\?.*$/, '')
                @@lc_request_uri.gsub!(/\/+/, '/');
             else
                @@lc_request_uri = @@request.request_uri
            end
        end

        if options.include?(:multi_site) && options[:multi_site]
            @@lc_multi_site = true
        end

        if options.include?(:verbose) && options[:verbose] || (@@lc_links.include?(:__linkfeed_debug__) && @@lc_links[:__linkfeed_debug__])
            @@lc_verbose = true
        end

        if options.include?(:charset) && options[:charset].size != 0
            @@lc_charset = options[:charset]
        end

        if options.include?(:fetch_remote_type) && options[:fetch_remote_type].size != 0
            @@lc_fetch_remote_type = options[:fetch_remote_type]
        end

        if options.include?(:socket_timeout) && options[:socket_timeout].is_a?(Numeric) && options[:socket_timeout] > 0
            @@lc_socket_timeout = options[:socket_timeout]
        end

        if options.include?(:force_show_code) &&options[:force_show_code] || (@@lc_links.include?(:__linkfeed_debug__) && @@lc_links[:__linkfeed_debug__])
            @@lc_force_show_code = true
        end


        if @@LINKFEED_USER.size==0
            self.raise_error("Constant LINKFEED_USER is not defined.")
        else

        self.load_links
        end

        end



    def load_links

        if @@lc_multi_site
            @@lc_links_db_file = RAILS_ROOT+'/tmp/'+@@LINKFEED_USER+'/linkfeed.'+@@lc_host+'.links.db'
        else
            @@lc_links_db_file = RAILS_ROOT+'/tmp/'+@@LINKFEED_USER+'/linkfeed.links.db'
        end

        if !File.exist?(@@lc_links_db_file)
            if FileUtils.touch(@@lc_links_db_file)              
                File.utime(Time.now, Time.now - @@lc_cache_lifetime,@@lc_links_db_file)
                File.chmod(0666, @@lc_links_db_file);
             else
                return self.raise_error("There is no file "+@@lc_links_db_file+". Fail to create. Set mode to 777 on the folder.")
            end
        end

        if !File.writable?(@@lc_links_db_file)
            self.raise_error("There is no permissions to write: "+@@lc_links_db_file+"! Set mode to 777 on the folder.")
        end

        #self.clearstatcache();

        if File.mtime(@@lc_links_db_file) < (Time.now-@@lc_cache_lifetime) ||
           (File.mtime(@@lc_links_db_file) < (Time.now-@@lc_cache_reloadtime) && (File.size(@@lc_links_db_file) == 0))

            FileUtils.touch(@@lc_links_db_file)

            path = '/'+@@LINKFEED_USER+'/'+@@lc_host.downcase+'/'+@@lc_charset.upcase

            if links = self.fetch_remote_file(@@lc_server, path)
                if links[0,12] == 'FATAL ERROR:'
                    self.raise_error(links)
                 else
                    self.lc_write(@@lc_links_db_file, links)
                end
            end
          end


        links = self.lc_read(@@lc_links_db_file)
        @@lc_file_change_date = File.mtime(@@lc_links_db_file)
        @@lc_file_size = links.length
        if links.length<=0
            @@lc_links = Array.new
            self.raise_error("Empty file.")
        else
        if !(@@lc_links = PHP.unserialize(links))
            @@lc_links = Array.new
            self.raise_error("Cann't unserialize data from file.")

        end
        end

        if @@lc_links.include?('__linkfeed_delimiter__') && @@lc_links['__linkfeed_delimiter__']
            @@lc_links_delimiter = @@lc_links['__linkfeed_delimiter__']
        end

        if @@lc_links.include?(@@lc_request_uri) && @@lc_links[@@lc_request_uri].is_a?(Array)
            @@lc_links_page = @@lc_links[@@lc_request_uri]
        end
        @@lc_links_count = @@lc_links_page.size
        @@lc_links
    end


    def return_links n = nil
        result = ''
        if @@lc_links.include?('__linkfeed_start__') && @@lc_links['__linkfeed_start__'].size != 0 &&
            (@@lc_links.include?('__linkfeed_robots__') && @@lc_links['__linkfeed_robots__'].include?(@@request.remote_addr) || @@lc_force_show_code)

            result += @@lc_links['__linkfeed_start__']
        end

        if (@@lc_links.include?('__linkfeed_robots__') && @@lc_links['__linkfeed_robots__'].include?(@@request.remote_addr) || @@lc_verbose)

            if @@lc_error != ''
                result += @@lc_error
            end

            result += '<!--REQUEST_URI='+@@request.request_uri+"-->\n"
            result += "\n<!--\n"
            result += 'L '+@@lc_version+"\n"
            result += 'REMOTE_ADDR='+@@request.remote_addr+"\n"
            result += 'request_uri='+@@lc_request_uri+"\n"
            result += 'charset='+@@lc_charset+"\n"
            result += 'is_static='+@@lc_is_static.to_s+"\n"
            result += 'multi_site='+@@lc_multi_site.to_s+"\n"
            result += 'file change date='+@@lc_file_change_date.to_s+"\n"
            result += 'lc_file_size='+@@lc_file_size.to_s+"\n"
            result += 'lc_links_count='+@@lc_links_count.to_s+"\n"
            result += 'left_links_count='+@@lc_links_page.size.to_s+"\n"
            result += 'n='+n.to_s+"\n"
            result += '-->'
        end

        if @@lc_links_page.is_a?(Array)
            total_page_links = @@lc_links_page.size

            if !n.is_a?(Numeric) || n > total_page_links
                n = total_page_links
            end

            links = Array.new;
            @@lc_links_page.reverse!
            n.times {links.push @@lc_links_page.pop}


            if  links.size > 0 && @@lc_links.include?('__linkfeed_before_text__')
               result += @@lc_links['__linkfeed_before_text__']
            end

            result += links.join(@@lc_links_delimiter)

            if  links.size > 0 && @@lc_links.include?('__linkfeed_after_text__')
               result += @@lc_links['__linkfeed_after_text__']
            end
        end
        if @@lc_links.include?('__linkfeed_end__') && @@lc_links['__linkfeed_end__'].size != 0 &&
            (@@lc_links.include?('__linkfeed_robots__') && @@lc_links['__linkfeed_robots__'].include?(@@request.remote_addr) || @@lc_force_show_code)

            result += @@lc_links['__linkfeed_end__']
        end
        result
    end


    def fetch_remote_file host, path
        user_agent = 'Linkfeed Client PHP '+@@lc_version
        resp=Net::HTTP.start(host) { |http|         
        http.get(path)
        }
        if resp.body
          resp.body
        else
        self.raise_error("Cann't connect to server: "+host+path)
        end
    end


     def lc_read filename
     open(filename, "rb") { |file|
       file.read
     }
    end

    def lc_write filename, data
    open(filename, "wb") { |file|
    file.write(data)
    }
    end    

    def raise_error msg
        @@lc_error = '<!--ERROR: '+msg+'-->'        
    end
  end
end
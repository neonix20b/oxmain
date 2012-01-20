require File.expand_path(File.dirname(__FILE__) + '/spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../lib/tl_client.rb')

DEFAULT_DB_FILE = 'a:7:{s:16:"__test_tl_link__";a:3:{s:3:"url";s:15:"http://test.com";s:4:"text";s:93:"Побочный PR-эффект ускоряет направленный маркетинг";s:6:"anchor";s:51:"Стратегия позиционирования";}s:17:"__trustlink_end__";s:15:"<!--9c7ec26b-->";s:19:"__trustlink_start__";s:15:"<!--9c7ec26b-->";s:20:"__trustlink_robots__";a:7:{i:0;s:11:"69.31.80.90";i:1;s:11:"69.31.80.91";i:2;s:11:"69.31.80.92";i:3;s:11:"69.31.80.93";i:4;s:11:"69.31.80.94";i:5;s:14:"63.218.226.114";i:6;s:15:"213.174.145.113";}s:23:"__trustlink_delimiter__";s:1:";";s:24:"__trustlink_after_text__";N;s:25:"__trustlink_before_text__";N;}'

describe "TlClient" do
  before :each do
    @request = Object.new
    @request.stub!(:request_uri).and_return('/')
    @request.stub!(:host).and_return('domain.ru')
    @request.stub!(:env).and_return({})
    @request.stub!(:parameters).and_return({})

    @tl = Trustlink::TlClient.new('a2321b3c234',@request, {:skip_load_links => true})
  end
  describe "инициализация скрипта и настройки" do
    it "должен создавать инстанс" do
      lambda{Trustlink::TlClient.new('a2321b3c234',@request, {:skip_load_links => true})}.should_not raise_error
    end

    it "не падаем на пустых параметрах" do
      lambda{Trustlink::TlClient.new(nil,nil)}.should_not raise_error
    end

    it "выход с ошибкой если не передать хэш пользователя" do
      @client = Trustlink::TlClient.new(nil,@request, {:skip_load_links => true})
      @client.error.should == "<!--ERROR: User is not defined-->\n"
    end

    it "выход с ошибкой если не передать request" do
      @client = Trustlink::TlClient.new('a2321b3c234', nil, {:skip_load_links => true})
      @client.error.should == "<!--ERROR: Request env is not provided-->\n"
    end

    it "опции по умолчанию" do
      @client = Trustlink::TlClient.new('a2321b3c234',@request, {:skip_load_links => true})
      Trustlink::TlClient.tl_user.should == 'a2321b3c234'
      @client.skip_load_links.should be_true
      Trustlink::TlClient.host.should == 'domain.ru'
      Trustlink::TlClient.is_static.should be_false
      @client.request_uri.should == '/'
      Trustlink::TlClient.data_folder.should == 'public/'
      Trustlink::TlClient.multi_site.should be_false
      Trustlink::TlClient.verbose.should be_false
      Trustlink::TlClient.charset.should == 'UTF-8'
      Trustlink::TlClient.force_show_code.should be_false
      Trustlink::TlClient.app_folder.should == ''
      @client.has_errors?.should be_false
    end

    it "корректная установка опций" do
      @client = Trustlink::TlClient.new('a2321b3c234',@request,
                                        {:skip_load_links => true, :host => 'testhost.ru', :is_static => true,
                                         :request_uri => '/test/path', :data_folder => '/test/data/folder', :multi_site => true,
                                         :verbose => true, :charset => 'CP1251', :force_show_code => true, :app_folder => '/test/app/folder'})
      Trustlink::TlClient.tl_user.should == 'a2321b3c234'
      @client.skip_load_links.should be_true
      Trustlink::TlClient.host.should == 'testhost.ru'
      Trustlink::TlClient.is_static.should be_true
      @client.request_uri.should == '/test/path'
      Trustlink::TlClient.data_folder.should == '/test/data/folder'
      Trustlink::TlClient.multi_site.should be_true
      Trustlink::TlClient.verbose.should be_true
      Trustlink::TlClient.charset.should == 'CP1251'
      Trustlink::TlClient.force_show_code.should be_true
      Trustlink::TlClient.app_folder.should == '/test/app/folder'
      @client.has_errors?.should be_false
    end

  end

  describe "загрузка ссылок" do

    it "забирает файл с сервера и сохраняет локально в Marshal виде" do

    end

    it "Для всех инстансов данные по ссылкам общие и не перезачитываются" do

    end

    it "Обновление кеша ссылок" do

    end


    it "отдает тестовые ссылки" do

    end

    it "отдает ссылки для страницы" do

    end

    it "для мультисайтов" do

    end

  end

  describe "вывод ссылок" do



  end

  describe "получение дб-файла" do
    it "получает корректный дб файл с сервера" do
      @tl.fetch_remote_file('db.trustlink.ru','/DEFAULT').should == DEFAULT_DB_FILE
    end
  end

  describe "чтение и запись дб-файла" do
    it "write_raw должен записывать, а read_raw должен считывать данные из файла" do
      @tl.write_raw('/tmp/tlclienttest.tmp', 'test data')
      @tl.read_raw('/tmp/tlclienttest.tmp').should == 'test data'
    end

    it "write должен записывать, а read должен считывать сериализованные данные из файла" do
      @tl.write('/tmp/tlclienttest.tmp', 'test marshal data')
      @tl.read_raw('/tmp/tlclienttest.tmp').should_not == 'test marshal data'
      Marshal.load(@tl.read_raw('/tmp/tlclienttest.tmp')).should == 'test marshal data'
      @tl.read('/tmp/tlclienttest.tmp').should == 'test marshal data'
    end

  end

  describe "обработка ошибок" do

    it "raise_error устанавливает признак ошибки в поле error" do
      @tl.error.should be_blank
      @tl.raise_error 'err'
      @tl.error.should == "<!--ERROR: err-->\n"
    end

    it "raise_error дописывает ошибки при их многократном возникновении в поле error" do
      @tl.error.should be_blank
      @tl.raise_error 'err'
      @tl.raise_error 'err2'
      @tl.error.should == "<!--ERROR: err-->\n<!--ERROR: err2-->\n"
    end

    it "has_errors? возвращает признак присутствия ошибок" do
      @tl.has_errors?.should be_false
      @tl.raise_error 'err'
      @tl.has_errors?.should be_true
    end

  end

end

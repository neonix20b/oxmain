module InviteHelper
	def invite_days(invite)
		if invite.delete_days > 0
			return " | Хостинг на #{invite.delete_days.to_s} дней."
		else
			return ""
		end
	end
end

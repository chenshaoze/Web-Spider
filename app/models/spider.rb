class Spider < ActiveRecord::Base
	validates :url, uniqueness: true
end

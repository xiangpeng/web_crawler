class CustInfo < ActiveRecord::Base
end

class CourtExecInfo < ActiveRecord::Base
  validates :md5, uniqueness: true
end
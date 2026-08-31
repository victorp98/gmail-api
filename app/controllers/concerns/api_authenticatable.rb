module ApiAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_api!
  end

  private

  def authenticate_api!
    expected = ENV["GMAIL_API_KEY"].to_s
    return if expected.blank?

    provided = request.headers["Authorization"].to_s.delete_prefix("Bearer ")
    valid = provided.bytesize == expected.bytesize && ActiveSupport::SecurityUtils.secure_compare(provided, expected)
    head :unauthorized unless valid
  end
end

class ImagesController < ApplicationController
  skip_before_action :require_login, raise: false

  def ogp
    text = ogp_params[:text] || "ギフト記録"
    image = OgpCreator.build(text)
    send_data image.to_blob, type: "image/png", disposition: "inline"
  end

  private

  def ogp_params
    params.permit(:text)
  end
end

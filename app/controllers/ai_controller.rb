class AiController < ApplicationController
  before_action :authenticate_user!

  def chat
    @query = params[:query].to_s.strip
    if @query.blank?
      @error = "質問を入力してください"
      return render partial: "ai/chat"
    end

    result = AssistantService.chat(query: @query, user: current_user)
    if result[:answer].nil?
      @error = "AI機能が利用できません"
    else
      @answer = result[:answer]
      @records = result[:records]
    end
    render partial: "ai/chat"
  end
end

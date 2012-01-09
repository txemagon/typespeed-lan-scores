class ScoresApp < ActionController::Metal
  include ActionController::Rendering

  WHOLE_FIELDS = %w{score total_count words_written user_name word_list rname duration init} 
  FIELDS = %w{puntos usuario nivel CPS PPM errores ocupacion } 

  append_view_path "app/views"

  def index
    @highscores = Fetcher.new(LAN).start
    render 
  end

  private 

  def logger 
    Rails.logger
  end

end

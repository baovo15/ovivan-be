class ShortUrlFinder < ApplicationFinder
  model ShortUrl

  attribute :code

  rule :code_cond, if: -> { code.present? }

  def code_cond
    model.find_by(code:)
  end
end
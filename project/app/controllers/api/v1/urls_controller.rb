module Api
  module V1
    class UrlsController < ApplicationController
      before_action :build_url_form

      # POST /encode
      def encode
        Rails.logger.info log_prefix("encode", "start", params: url_params.to_h)

        if @form.validate! && transaction(-> { @encode_url = Urls::EncodeService.call(@form) })
          Rails.logger.info log_prefix("encode", "success",
                                       url: @form.url,
                                       short_url: safe_short_url(@encode_url))

          return render "urls/encode"
        end

        Rails.logger.warn log_prefix("encode", "invalid_original_url", url: @form.url)
        raise Error::Urls::Encode::InvalidOriginalUrl
      rescue StandardError => e
        Rails.logger.error log_prefix("encode", "exception",
                                      error_class: e.class.name,
                                      message: e.message)
        raise
      end

      # POST /decode
      def decode
        Rails.logger.info log_prefix("decode", "start",
                                     short_url_param: @form.url,
                                     code: @form.extract_code)

        @presenter = short_url_presenter

        if @presenter.present? && @presenter.short_url.present?
          Rails.logger.info log_prefix("decode", "success",
                                       code: @form.extract_code,
                                       original_url: @presenter.short_url.original_url)

          return render "urls/decode"
        end

        Rails.logger.warn log_prefix("decode", "url_not_found", code: @form.extract_code)
        raise ::Error::Urls::Decode::UrlNotFound
      rescue StandardError => e
        Rails.logger.error log_prefix("decode", "exception",
                                      error_class: e.class.name,
                                      message: e.message)
        raise
      end

      private

      def url_params
        # Require an url from params
        params.require(:url)
        # Get the url from params
        params.permit(:url)
      rescue ActionController::ParameterMissing => e
        Rails.logger.warn("[UrlsController] #{e.message}")
        raise ::Error::General::Http::ParameterMissing.new("#{e.message}")
      end

      def build_url_form
        @form ||= UrlForm.new(url_params)
      end

      def short_url_presenter
        ShortUrls::IndexPresenter.new(code: @form.extract_code) if @form.valid?
      end

      def safe_short_url(record)
        record.respond_to?(:short_url) ? record.short_url : nil
      end
    end
  end
end

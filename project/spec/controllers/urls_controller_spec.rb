# spec/controllers/urls_controller_spec.rb
require "rails_helper"

RSpec.describe Api::V1::UrlsController, type: :controller do
  # Do NOT call render_views – we don't need templates for branch coverage.

  before do
    # avoid nil / missing method problems from logging helper in tests
    allow(controller).to receive(:log_prefix).and_return("prefix")
  end

  describe "POST #encode" do
    let(:url_param) { "https://example.com" }
    let(:form)      { instance_double(UrlForm, url: url_param) }

    before do
      # build_url_form (before_action) calls UrlForm.new(url_params)
      allow(UrlForm).to receive(:new).and_return(form)
    end

    context "when form is valid and transaction succeeds (then-branch of &&)" do
      let(:short_url_record) do
        instance_double(ShortUrl, short_url: "http://localhost:3000/EgjPwdJ0")
      end

      before do
        allow(form).to receive(:validate!).and_return(true)

        # transaction(-> { ... }) – run the block and return true
        allow(controller).to receive(:transaction)
                               .and_wrap_original do |_m, operation|
          operation.call
          true
        end

        allow(Urls::EncodeService).to receive(:call)
                                        .with(form)
                                        .and_return(short_url_record)
      end

      it "returns 200" do
        post :encode, params: { url: url_param }, as: :json

        expect(response).to have_http_status(:ok)
      end
    end

    context "when form is valid BUT transaction returns false (else-branch of &&)" do
      before do
        allow(form).to receive(:validate!).and_return(true)

        # emulate failed transaction WITHOUT raising
        allow(controller).to receive(:transaction)
                               .and_wrap_original do |_m, operation|
          operation.call
          false
        end
      end

      it "triggers the invalid branch (status is handled by Error::Handler)" do
        post :encode, params: { url: url_param }, as: :json

        # whatever your Error::Handler maps InvalidOriginalUrl to:
        # if you know it's 422, keep :unprocessable_entity;
        # if not, just assert it is an error (4xx/5xx).
        expect(response.status).to be_between(400, 599)
      end
    end

    context "when form is valid but service returns object WITHOUT short_url" do
      # exercises safe_short_url else branch
      let(:result) { double("EncodeResultWithoutShortUrl") }

      before do
        allow(form).to receive(:validate!).and_return(true)

        allow(controller).to receive(:transaction)
                               .and_wrap_original do |_m, operation|
          operation.call
          true
        end

        allow(Urls::EncodeService).to receive(:call).and_return(result)
      end

      it "still returns 200" do
        post :encode, params: { url: url_param }, as: :json

        expect(response).to have_http_status(:ok)
      end
    end

    context "when form is invalid (first operand of && is false)" do
      before do
        allow(form).to receive(:validate!).and_return(false)
      end

      it "returns an error status handled by Error::Handler" do
        post :encode, params: { url: "invalid-url" }, as: :json

        expect(response.status).to be_between(400, 599)
      end
    end
  end

  describe "POST #decode" do
    let(:short_url_param) { "http://short.host/AbCd1234" }  # must be a String
    let(:code)            { "AbCd1234" }

    let(:form) do
      instance_double(
        UrlForm,
        url: short_url_param,
        extract_code: code,
        valid?: true
      )
    end

    before do
      allow(UrlForm).to receive(:new).and_return(form)
    end

    context "when short url exists (presenter.short_url.present? => true)" do
      let(:short_url_record) do
        instance_double(
          ShortUrl,
          original_url: "https://example.com",
          present?: true
        )
      end

      let(:presenter) do
        instance_double(ShortUrls::IndexPresenter, short_url: short_url_record)
      end

      before do
        allow(ShortUrls::IndexPresenter).to receive(:new)
                                              .with(code: code)
                                              .and_return(presenter)
      end

      it "returns 200" do
        post :decode, params: { url: short_url_param }, as: :json
        puts "BODY: #{response.body}"  # optional debugging
        expect(response).to have_http_status(:ok)
      end
    end

    context "when short url does NOT exist (presenter.short_url.present? => false)" do
      let(:presenter) do
        instance_double(ShortUrls::IndexPresenter, short_url: nil)
      end

      before do
        allow(ShortUrls::IndexPresenter).to receive(:new)
                                              .with(code: code)
                                              .and_return(presenter)
      end

      it "hits the not-found branch (exact status depends on Error::Handler)" do
        post :decode, params: { url: short_url_param }, as: :json
        expect(response.status).to be_between(400, 599)
      end
    end
  end

  describe "#url_params" do
    context "when :url param is present" do
      it "returns permitted url params" do
        params = ActionController::Parameters.new(
          url: "https://example.com"
        )
        allow(controller).to receive(:params).and_return(params)

        result = controller.send(:url_params)

        expect(result).to be_a(ActionController::Parameters)
        expect(result[:url]).to eq("https://example.com")
        expect(result).to be_permitted
      end
    end

    context "when :url param is missing" do
      it "rescues ParameterMissing and raises custom Error::General::Http::ParameterMissing" do
        params = ActionController::Parameters.new({})
        allow(controller).to receive(:params).and_return(params)

        expect {
          controller.send(:url_params)
        }.to raise_error(Error::General::Http::ParameterMissing)
      end
    end
  end

  describe "#short_url_presenter" do
    let(:code) { "AbCd1234" }

    let(:form) do
      instance_double(
        UrlForm,
        extract_code: code,
        valid?: valid
      )
    end

    before do
      # mimic what build_url_form does in the controller
      controller.instance_variable_set(:@form, form)
    end

    context "when form is valid" do
      let(:valid)     { true }
      let(:presenter) { instance_double(ShortUrls::IndexPresenter) }

      it "initializes ShortUrls::IndexPresenter with extracted code and returns it" do
        expect(ShortUrls::IndexPresenter)
          .to receive(:new)
                .with(code: code)
                .and_return(presenter)

        result = controller.send(:short_url_presenter)

        expect(result).to eq(presenter)
      end
    end

    context "when form is invalid" do
      let(:valid) { false }

      it "does not initialize presenter and returns nil" do
        expect(ShortUrls::IndexPresenter).not_to receive(:new)

        result = controller.send(:short_url_presenter)

        expect(result).to be_nil
      end
    end
  end

end

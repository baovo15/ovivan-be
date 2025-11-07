Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  # Load routes for each Bounded Context (module)
  scope module: "api" do
    namespace :v1 do
      resources :urls, only: [] do
        collection do
          post :encode      # → POST /urls/encode
          post :decode      # → POST /urls/decode
        end
      end
    end
  end
end

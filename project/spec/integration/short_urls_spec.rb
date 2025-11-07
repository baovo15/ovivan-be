require 'swagger_helper'

RSpec.describe 'Articles API', swagger_doc: 'v1/swagger.yaml', type: :request, integration: true do
  path '/api/v1/articles' do
    get 'Retrieve all articles' do
      tags 'Articles'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'articles found' do
        run_test!
      end

      response '404', 'articles not found' do
        run_test!
      end
    end

    post 'Create a new article' do
      tags 'Articles'
      consumes 'application/json'
      security [bearerAuth: []]
      parameter name: :article, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string },
          content: { type: :string }
        },
        required: %w[title content]
      }

      response '201', 'article created' do
        run_test!
      end

      response '422', 'validation failed' do
        run_test!
      end

      response '400', 'transaction failed' do
        run_test!
      end
    end
  end

  path '/api/v1/articles/{id}' do
    parameter name: :id, in: :path, type: :integer, required: true

    get 'Retrieve a specific article' do
      tags 'Articles'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'article found' do
        run_test!
      end

      response '404', 'article not found' do
        run_test!
      end
    end

    put 'Update an article' do
      tags 'Articles'
      consumes 'application/json'
      security [bearerAuth: []]
      parameter name: :article, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string },
          content: { type: :string }
        },
        required: %w[title content]
      }

      response '201', 'article updated' do
        run_test!
      end

      response '422', 'update validation failed' do
        run_test!
      end

      response '400', 'transaction failed' do
        run_test!
      end
    end

    delete 'Delete an article' do
      tags 'Articles'
      security [bearerAuth: []]

      response '204', 'article deleted' do
        run_test!
      end

      response '400', 'deletion failed' do
        run_test!
      end
    end
  end
end

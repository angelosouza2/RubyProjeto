Rails.application.routes.draw do
  # Rotas do Devise para usuários normais
  devise_for :users

  # Rotas do Devise para administradores
  devise_for :admins

  # Área de administração para visualização de pagamentos
  namespace :admin do
    resources :payments, only: [:index]
  end

  # Rotas para pagamentos
  resources :payments, only: [:new, :create] do
    collection do
      get :success
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Rotas para PWA
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Rota raiz para iniciar com a tela de login dos usuários normais
  devise_scope :user do
    authenticated :user do
      root to: "payments#new", as: :authenticated_root
    end

    unauthenticated do
      root to: "devise/sessions#new", as: :unauthenticated_root
    end
  end
end

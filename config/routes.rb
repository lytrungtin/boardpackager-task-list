Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  resources :tasks, only: %i[new create show edit update] do
    # Completion is a state change modeled as its own RESTful resource,
    # not a custom verb route on tasks.
    resource :completion, only: %i[create destroy], module: :tasks
  end
end

Rails.application.routes.draw do
    root "profile#index"
    get "/profile/create", to: "profile#create"
end

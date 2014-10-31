Rails.application.routes.draw do
    root "profile#index"
    get "/profile/create", to: "profile#create"
    get "/profile/edit", to: "profile#edit"
    get "/profile/compare", to: "profile#compare"
end

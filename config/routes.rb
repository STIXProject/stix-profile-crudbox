Rails.application.routes.draw do
    root "profile#index"
    get "/profile/create", to: "profile#create"
    get "/profile/edit", to: "profile#edit"
    get "/profile/compare", to: "profile#compare"

    post "/profile/upload", to: "profile#upload"
    get "/profile/created", to: "profile#created"
    get "/profile/download", to: "profile#download"
end

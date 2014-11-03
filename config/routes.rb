Rails.application.routes.draw do
    root "profile#index"
    get "/profile/create", to: "profile#create"
    get "/profile/edit", to: "profile#edit"
    get "/profile/start_edit", to: "profile#start_edit"
    post "/profile/open_profile", to: "profile#open_profile"

    get "/profile/compare", to: "profile#compare"
    post "/profile/do_compare", to: "profile#do_compare"

    post "/profile/upload", to: "profile#upload"
    get "/profile/created", to: "profile#created"
    get "/profile/download", to: "profile#download"
end

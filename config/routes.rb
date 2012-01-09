Typespeed::Application.routes.draw do

  match 'scores' => ScoresApp.action(:index)
  root :to => ScoresApp.action(:index)
end

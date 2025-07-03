defmodule MyApp.Users.JSONIndexResponse do
  use Valspec.Schema

  valspec_schema do
    embeds_many(:data, MyApp.Users.UserSchema)
  end
end

defmodule MyApp.Users.JSONIndexResponse do
  use Valspec

  valspec_schema do
    embeds_many(:data, MyApp.Users.UserSchema)
  end
end

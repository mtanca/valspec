defmodule MyApp.Users.CallbackSchema do
  use Valspec.Schema

  valspec_schema do
    embeds_one(:user, MyApp.Users.UserSchema)
  end
end

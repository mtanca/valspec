defmodule MyApp.Users.CallbackSchema do
  use Valspec

  valspec_schema do
    embeds_one(:user, MyApp.Users.UserSchema)
  end
end

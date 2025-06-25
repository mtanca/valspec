defmodule MyApp.Users.JSONResponse do
  use Valspec

  valspec_schema do
    embeds_one(:data, MyApp.Users.UserSchema)
  end
end

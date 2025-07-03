defmodule MyApp.Users.UserSchema do
  use Valspec.Schema

  valspec_schema do
    field(:first_name, :string)
    field(:last_name, :string)
    field(:age, :integer)
  end
end

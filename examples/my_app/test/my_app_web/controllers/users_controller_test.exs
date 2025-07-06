defmodule MyAppWeb.UsersControllerTest do
  use MyAppWeb.ConnCase

  describe "POST /users" do
    test "with invalid params", %{conn: conn} do
      invalid_params = %{hello: "world"}
      conn = post(conn, ~p"/users", invalid_params)

      assert json_response(conn, 400) ==
               %{"errors" => %{"age" => ["can't be blank"], "first_name" => ["can't be blank"]}}
    end

    test "with valid params", %{conn: conn} do
      valid_params = %{first_name: "Hello", age: 20}
      conn = post(conn, ~p"/users", valid_params)

      assert json_response(conn, 200)
    end
  end

  describe "PUT /users/id" do
    test "with invalid params", %{conn: conn} do
      invalid_params = %{first_name: nil}
      conn = put(conn, ~p"/users/1", invalid_params)

      assert json_response(conn, 400) ==
               %{"errors" => %{"age" => ["can't be blank"], "first_name" => ["can't be blank"]}}
    end

    test "with valid params", %{conn: conn} do
      valid_params = %{first_name: "Hello", age: 25}

      conn = put(conn, ~p"/users/1", valid_params)

      assert json_response(conn, 200)
    end
  end
end

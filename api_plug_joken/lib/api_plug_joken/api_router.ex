defmodule ApiRouter do
  use Plug.Router
  use Plug.ErrorHandler
  import Joken

  alias ApiPlugJoken.DB.User
  alias ApiPlugJoken.DB.JWT

  @skip_auth %{joken_skip: true}
  @verify_get %{joken_on_verifying: &ApiRouter.verify/0}
  
  plug Plug.Parsers, parsers: [:json], json_decoder: Poison
  plug :match
  plug Joken.Plug, on_verifying: &ApiRouter.verify/0, on_error: &ApiRouter.error_logging/2
  plug :dispatch

  post "/user/sign_up", private: @skip_auth do
    user = User.validate_and_parse(conn.body_params)
    |> User.write!

    jwt = JWT.generate(user)

    generate_token_and_reply(conn, 201, user, jwt)
  end

  post "/user/sign_in", private: @skip_auth do
    require User
    require Exquisite

    body_name = conn.body_params["name"]
    body_email = conn.body_params["email"]
    
    result = User.where!(name == body_name and email == body_email)
    |> Amnesia.Selection.values

    user = case result do
             [] ->
               raise "Unauthenticated"
             [user] ->
               user
             _ ->
               # mais de um!
               raise "Unauthenticated"
           end
    
    jwt = JWT.generate(user)
    generate_token_and_reply(conn, 200, user, jwt)    
  end

  # so executa se tiver um token vlido!
  get "/user/:user_id" do
    require User
    require Exquisite

    user = User.read! String.to_integer(user_id)

    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(200, Poison.encode!(user))
  end

  match _, private: @skip_auth, do: send_resp(conn, 404, "oops")

  def error_logging(conn, message) do
    {conn, message}
  end
  
  def verify do
    %Joken.Token{}
    |> with_json_module(Poison)
    |> with_exp
    |> with_iat
    |> with_nbf
    |> with_iss("Joken Showcase Server")
    |> with_aud("RESTCLIENT")
    |> with_validation("exp", &(&1 > current_time))
    |> with_validation("iat", &(&1 < current_time))
    |> with_validation("nbf", &(&1 < current_time))
    |> with_validation("iss", &(&1 == "Joken Showcase Server"))
    |> with_validation("aud", &(&1 == "RESTCLIENT"))
    |> with_signer(hs256("A galinha nao amamenta"))
  end
  
  defp handle_errors(conn,  %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, conn.status, "Something went wrong")
  end
  
  defp validate_auth(["Bearer " <> jwt_token]) do
    require JWT
    require Exquisite

    jwt = jwt_token
    |> token
    |> with_validation("exp", &(&1 > current_time))
    |> with_validation("iat", &(&1 < current_time))
    |> with_validation("nbf", &(&1 < current_time))
    |> with_validation("iss", &(&1 == "Joken Showcase Server"))
    |> with_validation("aud", &(&1 == "RESTCLIENT"))
    |> verify(hs256("A galinha nao amamenta"), as: JWT)
    |> get_claims

    [jwt] = JWT.where!(jti == jwt.jti)
    |> Amnesia.Selection.values
  end
  defp validate_auth(_), do: raise "Unauthenticated"
  
  defp generate_token_and_reply(conn, status, user, jwt) do

    compact_jwt = token
    |> with_claims(jwt)
    |> sign(hs256("A galinha nao amamenta"))
    |> get_compact

    resp_body = Poison.encode!(Map.put(user, :token, compact_jwt))

    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(status, resp_body)
  end
  
end

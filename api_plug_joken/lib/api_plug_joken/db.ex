use Amnesia

defdatabase ApiPlugJoken.DB do

  deftable User, [{:id, autoincrement}, :name, :email],
  [type: :ordered_set, index: [:email]] do

    def validate_and_parse(%{"name" => rname, "email" => remail}) do
      if is_nil(remail), do: raise "email is required"
      %User{name: rname, email: remail} |> User.write!
    end
  end

  deftable JWT, [:jti, :exp, :iat, :nbf, :iss, :aud], type: :bag do
    import Joken

    defimpl Joken.Claims, for: JWT do
      def to_claims(data) do
        Enum.reduce Map.from_struct(data), %{}, fn({key, value}, acc) ->
          case key do
            key when is_atom(key) ->
              Map.put(acc, Atom.to_string(key), value)
            key when is_binary(key) ->
              Map.put(acc, key, value)
            _ ->
              raise "Claim keys must be binaries"
          end
        end
      end
    end
    
    def generate(%{id: id}) do
      %JWT{
        exp: current_time + (2 * 60 * 60),
        iat: current_time,
        nbf: current_time - 1,
        iss: "Joken Showcase Server",
        aud: "RESTCLIENT",
        jti: id}
      |> JWT.write!
    end
  end
end

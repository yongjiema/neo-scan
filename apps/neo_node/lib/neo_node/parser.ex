defmodule NeoNode.Parser do
  defp parse16("0x" <> rest), do: parse16(rest)

  defp parse16(string) do
    Base.decode16!(string, case: :mixed)
  end

  # Base.decode64!(string, padding: false)
  defp parse58(string), do: Base58.decode(string)

  defp parse_asset_type("GoverningToken"), do: :governing_token
  defp parse_asset_type("UtilityToken"), do: :utility_token
  defp parse_asset_type("Token"), do: :token
  defp parse_asset_type("Share"), do: :share

  defp parse_transaction_type("PublishTransaction"), do: :publish_transaction
  defp parse_transaction_type("RegisterTransaction"), do: :register_transaction
  defp parse_transaction_type("IssueTransaction"), do: :issue_transaction
  defp parse_transaction_type("MinerTransaction"), do: :miner_transaction
  defp parse_transaction_type("ContractTransaction"), do: :contract_transaction
  defp parse_transaction_type("ClaimTransaction"), do: :claim_transaction
  defp parse_transaction_type("InvocationTransaction"), do: :invocation_transaction
  defp parse_transaction_type("EnrollmentTransaction"), do: :enrollment_transaction
  defp parse_transaction_type("StateTransaction"), do: :state_transaction

  defp parse_float(nil), do: nil
  defp parse_float(string), do: elem(Float.parse(string), 0)

  defp parse_claims(nil), do: []
  defp parse_claims(claims), do: Enum.map(claims, &parse_vin/1)

  defp ensure_integer(integer) when is_integer(integer), do: integer

  defp parse_vin(vin) do
    %{
      vout_transaction_hash: parse16(vin["txid"]),
      vout_n: vin["vout"]
    }
  end

  defp parse_vout(vout) do
    %{
      address: parse58(vout["address"]),
      asset: parse16(vout["asset"]),
      n: vout["n"],
      value: parse_float(vout["value"])
    }
  end

  defp parse_transaction_asset(nil, _), do: nil

  defp parse_transaction_asset(asset, transaction) do
    asset
    |> Map.merge(%{"id" => transaction["txid"], "issuer" => asset["admin"]})
    |> parse_asset()
  end

  def parse_contract(contract) do
    %{
      author: contract["author"],
      code_version: contract["code_version"],
      email: contract["email"],
      hash: parse16(contract["hash"]),
      name: contract["name"],
      parameters: contract["parameters"],
      properties: contract["properties"],
      return_type: contract["returntype"],
      script: if(is_nil(contract["script"]), do: nil, else: parse16(contract["script"])),
      version: contract["version"]
    }
  end

  def parse_asset(asset) do
    %{
      admin: parse58(asset["admin"]),
      amount: parse_float(asset["amount"]),
      available: parse_float(asset["available"]),
      expiration: asset["expiration"],
      frozen: asset["frozen"],
      transaction_hash: parse16(asset["id"]),
      issuer: parse58(asset["issuer"]),
      name: asset["name"],
      owner: asset["owner"],
      precision: asset["precision"],
      type: parse_asset_type(asset["type"]),
      version: asset["version"]
    }
  end

  def parse_block(block) do
    %{
      confirmations: block["confirmations"],
      hash: parse16(block["hash"]),
      index: block["index"],
      merkle_root: parse16(block["merkleroot"]),
      next_block_hash:
        if(is_nil(block["nextblockhash"]), do: nil, else: parse16(block["nextblockhash"])),
      previous_block_hash: parse16(block["previousblockhash"]),
      next_consensus: parse58(block["nextconsensus"]),
      version: block["version"],
      nonce: parse16(block["nonce"]),
      script: block["script"],
      size: ensure_integer(block["size"]),
      time: DateTime.from_unix!(block["time"]),
      tx: Enum.map(block["tx"], &parse_block_transaction(&1, block))
    }
  end

  defp parse_block_transaction(transaction, block) do
    transaction
    |> Map.merge(%{"blockhash" => block["hash"], "blocktime" => block["time"]})
    |> parse_transaction()
  end

  def parse_transaction(transaction) do
    %{
      asset: parse_transaction_asset(transaction["asset"], transaction),
      attributes: transaction["attributes"],
      nonce: transaction["nonce"],
      scripts: parse_scripts(transaction),
      block_time: DateTime.from_unix!(transaction["blocktime"]),
      block_hash: parse16(transaction["blockhash"]),
      size: transaction["size"],
      sys_fee: parse_float(transaction["sys_fee"]),
      net_fee: parse_float(transaction["net_fee"]),
      hash: parse16(transaction["txid"]),
      type: parse_transaction_type(transaction["type"]),
      version: transaction["version"],
      vins: Enum.map(transaction["vin"], &parse_vin/1),
      vouts: Enum.map(transaction["vout"], &parse_vout/1),
      claims: parse_claims(transaction["claims"])
    }
  end

  defp parse_scripts(transaction) do
    scripts = transaction["scripts"]
    contract = transaction["contract"]
    script = transaction["script"]

    scripts ++
      if(is_nil(contract), do: [], else: [%{"contract" => contract}]) ++
      if is_nil(script), do: [], else: [%{"script" => script}]
  end
end

export CONSUL_BOOTSTRAP_TOKEN=$(terraform output -raw consul_token)

echo "$CONSUL_BOOTSTRAP_TOKEN" > consul_token.txt

echo ""
echo "Copy your Consul Bootstrap Token this command:"
echo ""
echo "cat consul_token.txt | pbcopy"
echo ""
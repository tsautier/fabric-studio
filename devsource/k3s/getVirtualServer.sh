token=$(echo '{"username":"admin","password":"00Penwin$","vdom":"root"}' | base64)
URL="https://fortiweb.fortidemo.ch:443/api/v2.0/cmdb"

echo ""
echo "curl -X GET -H 'Content-type: application/json' \\"
echo "     -H 'Accept: application/json' \\"
echo "     -H "Authorization: $token" \\"
echo "     $URL/server-policy/policy?mkey=k8s-apps-server-policy | jq -r"

curl -X GET -H 'Content-type: application/json' \
     -H 'Accept: application/json' \
     -H "Authorization: $token" \
     $URL/server-policy/policy?mkey=k8s-apps-server-policy 2>/dev/null | jq -r

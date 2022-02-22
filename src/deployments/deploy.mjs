#!/usr/bin/env zx

const CHAIN_ID_TO_RPC = {
  100: process.env.RPC_GNOSIS_CHAIN,
  42: process.env.RPC_KOVAN,
  300: process.env.RPC_OPTIMISM_ON_GNOSIS_CHAIN,
  69: process.env.RPC_OPTIMISM_KOVAN
}

function parseForgeCreateDeploy(output) {
  const lines = output.split('\n');
  const address = lines[lines.length - 3].split(':').slice(1)[0].trim();
  return address
}

async function setTrustedForwarder(chainId, address, trustedForwarder) {
  if(!Object.keys(CHAIN_ID_TO_RPC).includes(chainId.toString())) {
    throw new Error("Can't call on chainId: " + chainId)
  }
  const oldRPCUrl = process.env.RPC_URL
  process.env.RPC_URL = CHAIN_ID_TO_RPC[chainId]
  await $`bash src/deployments/set-trusted-forwarder-address.sh ${address} ${trustedForwarder}` 
  process.env.RPC_URL = oldRPCUrl
  console.log("Trusted forwarder set for address", address, "on chain id", chainId)
}

const L1_BRIDGES = {
  100: "0x4324fdD26161457f4BCc1ABDA87709d3Be8Fd10E",
  42: "0x4361d0F75A0186C05f971c566dC6bEa5957483fD"
}

const TRUSTED_FORWARDERS = {
  100: "0x7eEae829DF28F9Ce522274D5771A6Be91d00E5ED",
  42: "0x7eEae829DF28F9Ce522274D5771A6Be91d00E5ED",
  300: "0x39A2431c3256028a07198D2D27FD120a1f81ecae", //TODO @ludns we need to update this to the right forwarder
  69: "0x39A2431c3256028a07198D2D27FD120a1f81ecae"
}

const L2_BRIDGE = "0x4200000000000000000000000000000000000007"

const PRIVATE_KEY = process.env.PRIVATE_KEY

let deployments = {
  persona: {},
  personaMirror: {}
}

// const L1_L2_PAIR = [[100, 300], [42, 69]]
const L1_L2_PAIR = [[42, 69]]

for(const [L1, L2] of L1_L2_PAIR.values()) {

  if(!Object.keys(CHAIN_ID_TO_RPC).includes(L1.toString())) {
    throw new Error("Can't deploy on chainId: " + L1)
  }

  if(!Object.keys(CHAIN_ID_TO_RPC).includes(L2.toString())) {
    throw new Error("Can't deploy on chainId: " + L2)
  }

  const RPC_L1 = CHAIN_ID_TO_RPC[L1];
  const RPC_L2 = CHAIN_ID_TO_RPC[L2];

  console.log("Using RPC (l1): " + RPC_L1)
  console.log("Using RPC (l2): " + RPC_L2)

  const NAME = "Channel"
  const SYMBOL = "LTX-CHANNEL"
  process.env.PKEY = PRIVATE_KEY

  const L1_BRIDGE = L1_BRIDGES[L1];

  process.env.RPC_URL = RPC_L1
  const {stdout: tokenURIGeneratorOutput} = await $`bash src/deployments/deploy-simple-persona-token-uri-generator.sh`
  const tokenURIGeneratorAddress = parseForgeCreateDeploy(tokenURIGeneratorOutput)

  const {stdout: l1Output} = await $`bash src/deployments/deploy-l1.sh ${NAME} ${SYMBOL} ${L1_BRIDGE} ${tokenURIGeneratorAddress}`
  const l1Address = parseForgeCreateDeploy(l1Output)

  console.log(chalk.green(`L1 Persona contract deployed at: ${l1Address}`))

  process.env.RPC_URL = RPC_L2
  const {stdout: l2Output} = await $`bash src/deployments/deploy-l2.sh ${l1Address} ${L2_BRIDGE}`
  const l2Address = parseForgeCreateDeploy(l2Output)

  console.log(chalk.green(`L2 Persona contract deployed at: ${l2Address}`))

  process.env.RPC_URL = RPC_L1
  await $`bash src/deployments/set-persona-mirror-address.sh ${l1Address} ${l2Address}`

  deployments["persona"][L1] = l1Address
  deployments["personaMirror"][L2] = l2Address
  await setTrustedForwarder(L1, l1Address, TRUSTED_FORWARDERS[L1])
  await setTrustedForwarder(L2, l2Address, TRUSTED_FORWARDERS[L2])
}


fs.writeFileSync('deployment.json', JSON.stringify(deployments))
let README = fs.readFileSync('README.template.md',
{encoding:'utf8', flag:'r'});

for(const [L1, L2] in L1_L2_PAIR) {
  README = README.replace(`{{{${L1}:l1Address}}}`, deployments[L1])
  README = README.replace(`{{{${L2}:l2Address}}}`, deployments[L2])
}
fs.writeFileSync('README.md', README)

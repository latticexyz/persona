#!/usr/bin/env zx

const deploymentFile = fs.readFileSync('deployment.json', {encoding: 'utf8', flag: 'r'})
const { persona } = JSON.parse(deploymentFile)

const CHAIN_ID_TO_RPC = {
  100: process.env.RPC_GNOSIS_CHAIN,
  42: process.env.RPC_KOVAN
}

const PRIVATE_KEY = process.env.PRIVATE_KEY

const chainId = parseInt(argv["_"][1])

if(!Object.keys(CHAIN_ID_TO_RPC).includes(chainId.toString())) {
  throw new Error("Can't use the registry on chainId: " + chainId)
}

const RPC = CHAIN_ID_TO_RPC[chainId];

console.log("Using RPC: " + RPC)

const PERSONA_ADDRESS = persona[chainId] 

if(!PERSONA_ADDRESS) {
  throw new Error("No address for deployment on chain id: " + chainId)
}
process.env.RPC_URL = RPC
process.env.PKEY = PRIVATE_KEY

const SUBTASK = await question('Choose subtask: ', {
  choices: ['MINT', 'ADD_MINTER']
})
if(SUBTASK === 'MINT') {
  const address = await question('Address of receiver: ')
  await $`bash src/tasks/mint/mint.sh ${PERSONA_ADDRESS} ${address}`
  console.log(chalk.bold.green("Done!"))
} else if(SUBTASK === 'ADD_MINTER') {
  const address = await question('Address of minter: ')
  await $`bash src/tasks/mint/add-minter.sh ${PERSONA_ADDRESS} ${address}`
  console.log(chalk.bold.green("Done!"))
}
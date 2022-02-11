#!/usr/bin/env zx

function parseForgeCreateDeploy(output) {
  const lines = output.split('\n');
  const address = lines[lines.length - 2].split(':').slice(1)[0].trim();
  return address
}

const deploymentFile = fs.readFileSync('deployment.json', {encoding: 'utf8', flag: 'r'})
const { l1: L1_ADDRESS, l2: L2_ADDRESS} = JSON.parse(deploymentFile)


const L1_BRIDGE = "0x4324fdD26161457f4BCc1ABDA87709d3Be8Fd10E"
const L2_BRIDGE = "0x4200000000000000000000000000000000000007"
const PRIVATE_KEY = await question('Private key: ')

const {stdout: l2Output} = await $`bash src/deployments/deploy-l2.sh ${L1_ADDRESS} ${L2_BRIDGE} ${PRIVATE_KEY}`
const l2Address = parseForgeCreateDeploy(l2Output)

console.log(chalk.green(`L2 Persona contract deployed at: ${l2Address}`))

await $`bash src/deployments/set-persona-mirror-address.sh ${L1_ADDRESS} ${l2Address} ${PRIVATE_KEY}`

const DEPLOYMENT = {
  l1: L1_ADDRESS,
  l2: l2Address
}

fs.writeFileSync('deployment.json', JSON.stringify(DEPLOYMENT))
let README = fs.readFileSync('README.template.md',
{encoding:'utf8', flag:'r'});
README = README.replace('{{{l1Address}}}', L1_ADDRESS)
README = README.replace('{{{l2Address}}}', l2Address)
fs.writeFileSync('README.md', README)
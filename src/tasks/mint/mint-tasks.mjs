#!/usr/bin/env zx


const deploymentFile = fs.readFileSync('deployment.json', {encoding: 'utf8', flag: 'r'})
const { l1: L1_ADDRESS, l2: L2_ADDRESS} = JSON.parse(deploymentFile)

const PRIVATE_KEY = await question('Private key: ')
const SUBTASK = await question('Choose subtask: ', {
  choices: ['MINT', 'ADD_MINTER']
})
if(SUBTASK === 'MINT') {
  const address = await question('Address of receiver: ')
  await $`bash src/tasks/mint/mint.sh ${L1_ADDRESS} ${address} ${PRIVATE_KEY}`
  console.log(chalk.bold.green("Done!"))
} else if(SUBTASK === 'ADD_MINTER') {
  const address = await question('Address of minter: ')
  await $`bash src/tasks/mint/add-minter.sh ${L1_ADDRESS} ${address} ${PRIVATE_KEY}`
  console.log(chalk.bold.green("Done!"))
}
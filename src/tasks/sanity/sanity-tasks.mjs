#!/usr/bin/env zx

const deploymentFile = fs.readFileSync('deployment.json', {encoding: 'utf8', flag: 'r'})
const { l1: L1_ADDRESS, l2: L2_ADDRESS} = JSON.parse(deploymentFile)

const SUBTASK = await question('Choose subtask: ', {
  choices: ['CHECK_OWNER']
})
if(SUBTASK === 'CHECK_OWNER') {
  const personaId = await question('Persona ID on L2: ')
  await $`bash src/tasks/sanity/get-owner-of-persona-mirror.sh ${L2_ADDRESS} ${personaId}`
}
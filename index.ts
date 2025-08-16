import { $ } from 'bun'
import { mkdirSync } from 'node:fs'
import { basename, join } from 'node:path'
import { cwd } from 'node:process'
import readline from 'node:readline/promises'

const contextDir = join(__dirname, 'contexts')
const globalContext = join(contextDir, 'global')

const projectPath = cwd()
const projectName = basename(projectPath)
const projectLocalContext = join(contextDir, projectName, '.local')
const containerName = `opencode-${projectName}`

async function containerExists() {
    const cmd = await $`podman container exists ${containerName}`.nothrow()
    return cmd.exitCode === 0
}

async function createContainer() {
    mkdirSync(projectLocalContext, { recursive: true })
    console.log(`Creating container ${containerName}`)
    await $`podman run -it \
        --name ${containerName} \
        -v ${globalContext}/.config/opencode/:/root/.config/opencode:rw \
        -v ${projectLocalContext}:/root/.local:rw \
        -v ${projectPath}:/app:rw \
        opencode opencode .`
}

async function removeContainer() {
    console.log(`Removing container ${containerName}`)
    await $`podman rm -f ${containerName}`.quiet()
}

async function reuseContainer() {
    await $`podman start -ai ${containerName}`
}

if (await containerExists()) {
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout,
    })
    const answer = await rl.question('Do you want to (r)euse the existing container or destroy and create a (n)ew one? [R/n]: ')
    rl.close()
    const option = answer.trim().toLowerCase()[0] || 'r'
    if (option === 'n') {
        await removeContainer()
        await createContainer()
    } else {
        await reuseContainer()
    }
} else {
    await createContainer()
}

import fs from 'node:fs/promises'
import {basename, join} from 'node:path'
import process from 'node:process'
import readline from 'node:readline/promises'
import {parseArgs} from 'node:util'
import {$} from 'bun'

const contextDir = join(import.meta.dirname, 'contexts')
const globalContext = join(contextDir, 'global')

const {values} = parseArgs({
	args: Bun.argv,
	options: {
		'project-path': {type: 'string', short: 'p'},
		'project-name': {type: 'string', short: 'n'},
		help: {type: 'boolean', short: 'h'},
	},
	strict: true,
	allowPositionals: true,
})

if (values.help) {
	console.log(`Usage: oc [--project-path <path>] [--project-name <name>] [--help]

Options:
  --project-path, -p   Path to the project directory (default: current working directory)
  --project-name, -n   Name of the project (default: basename of project path)
  --help, -h           Show this help message and exit
`)
	process.exit(0)
}

const projectPath = values['project-path'] ?? process.cwd()
const projectName = values['project-name'] ?? basename(projectPath)
const projectLocalContext = join(contextDir, projectName, '.local')
const containerName = `opencode-${projectName}`

async function containerExists() {
	const cmd = await $`podman container exists ${containerName}`.nothrow()
	return cmd.exitCode === 0
}

async function ensureProjectLocalContextExists() {
	if (!(await fs.exists(projectLocalContext))) {
		const entries = await fs.readdir(contextDir, {withFileTypes: true})
		const reference = entries.find(
			(f) => f.name !== 'global' && f.isDirectory(),
		)
		await fs.mkdir(projectLocalContext, {recursive: true})
		if (reference) {
			console.log(`Copying context from ${reference.name} project`)
			await fs.cp(
				join(contextDir, reference.name, '.local'),
				projectLocalContext,
				{recursive: true},
			)
		}
	}
}

async function createContainer() {
	await ensureProjectLocalContextExists()
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
	const answer = await rl.question(
		'Do you want to (r)euse the existing container or destroy and create a (n)ew one? [R/n]: ',
	)
	rl.close()
	const option = answer.trim().toLowerCase()[0]
	if (option === 'n') {
		await removeContainer()
		await createContainer()
	} else {
		await reuseContainer()
	}
} else {
	await createContainer()
}

const { execSync } = require('child_process')
const chokidar = require('chokidar')

// Exit the process when standard input closes due to:
//   https://hexdocs.pm/elixir/1.10.2/Port.html#module-zombie-operating-system-processes
//
process.stdin.on('end', function () {
  console.log('standard input end')
  process.exit()
})

process.stdin.resume()

let timer
function build(path) {
  timer = null
  console.log('Building nuxt js files', path)
  execSync('npm run generate', { stdio: 'inherit' })
  console.log('Listening to changes')
}

build('')

// Set up chokidar to watch all elm files and rebuild the elm app ignoring process errors
chokidar
  .watch(['**/*.vue', '**/*.js'], {
    ignored: ['node_modules', '.nuxt', 'dev.js'],
  })
  .on('change', () => {
    if (timer) {
      clearTimeout(build)
    }

    timer = setTimeout(build, 1000)
  })

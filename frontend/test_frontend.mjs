#!/usr/bin/env node
/**
 * Frontend Test Script for CI/CD Pipeline Health Dashboard
 * 
 * This script performs basic validation of the frontend build process
 * and configuration. Run this after setting up the frontend.
 */

import { readFileSync, existsSync } from 'fs'
import { execSync } from 'child_process'
import path from 'path'

const tests = []
const errors = []

function test(name, fn) {
  tests.push({ name, fn })
}

function runTests() {
  console.log('🧪 Running Frontend Tests for CI/CD Dashboard')
  console.log('=' * 50)
  
  let passed = 0
  let failed = 0
  
  tests.forEach(({ name, fn }) => {
    try {
      fn()
      console.log(`✅ ${name}`)
      passed++
    } catch (error) {
      console.log(`❌ ${name}: ${error.message}`)
      failed++
      errors.push({ test: name, error: error.message })
    }
  })
  
  console.log('\n' + '=' * 50)
  console.log(`📊 Test Results: ${passed} passed, ${failed} failed`)
  
  if (errors.length > 0) {
    console.log('\n🔍 Error Details:')
    errors.forEach(({ test, error }) => {
      console.log(`   ${test}: ${error}`)
    })
  }
  
  if (failed === 0) {
    console.log('\n🎉 All frontend tests passed! Ready to run.')
  } else {
    console.log('\n⚠️  Some tests failed. Please check the configuration.')
    process.exit(1)
  }
}

// Test: package.json exists and is valid
test('package.json exists and is valid', () => {
  const packagePath = './package.json'
  if (!existsSync(packagePath)) {
    throw new Error('package.json not found')
  }
  
  const packageJson = JSON.parse(readFileSync(packagePath, 'utf8'))
  
  if (!packageJson.dependencies?.react) {
    throw new Error('React dependency missing')
  }
  
  if (!packageJson.dependencies?.recharts) {
    throw new Error('Recharts dependency missing')
  }
  
  if (!packageJson.dependencies?.axios) {
    throw new Error('Axios dependency missing')
  }
  
  if (!packageJson.scripts?.dev) {
    throw new Error('dev script missing')
  }
})

// Test: Source files exist
test('Required source files exist', () => {
  const requiredFiles = [
    './src/App.jsx',
    './src/main.jsx',
    './index.html',
    './vite.config.js'
  ]
  
  requiredFiles.forEach(file => {
    if (!existsSync(file)) {
      throw new Error(`Required file missing: ${file}`)
    }
  })
})

// Test: App.jsx contains required components
test('App.jsx contains required functionality', () => {
  const appContent = readFileSync('./src/App.jsx', 'utf8')
  
  const requiredFeatures = [
    'MetricCard',
    'StatusPill',
    'LogsModal',
    'LineChart',
    'PieChart',
    'WebSocket',
    'BACKEND_URL'
  ]
  
  requiredFeatures.forEach(feature => {
    if (!appContent.includes(feature)) {
      throw new Error(`Required feature missing in App.jsx: ${feature}`)
    }
  })
})

// Test: Environment configuration
test('Environment configuration is set up', () => {
  const viteConfigExists = existsSync('./vite.config.js')
  const envSampleExists = existsSync('../.env.sample')
  
  if (!viteConfigExists) {
    throw new Error('vite.config.js not found')
  }
  
  // Check if VITE_BACKEND_URL is properly configured in the app
  const appContent = readFileSync('./src/App.jsx', 'utf8')
  if (!appContent.includes('VITE_BACKEND_URL')) {
    throw new Error('VITE_BACKEND_URL environment variable not configured')
  }
})

// Test: Build process (if npm is available)
test('Project can be built (npm available)', () => {
  try {
    // Check if node_modules exists
    if (!existsSync('./node_modules')) {
      console.log('   📦 Installing dependencies first...')
      execSync('npm install', { stdio: 'pipe' })
    }
    
    // Try building the project
    execSync('npm run build', { stdio: 'pipe' })
    
    // Check if dist folder was created
    if (!existsSync('./dist')) {
      throw new Error('Build output (dist folder) not created')
    }
    
    console.log('   📦 Build completed successfully')
  } catch (error) {
    throw new Error(`Build failed: ${error.message}`)
  }
})

// Test: Start script exists and is executable
test('Start script is available', () => {
  const startScriptExists = existsSync('./start.sh')
  
  if (!startScriptExists) {
    throw new Error('start.sh script not found')
  }
  
  try {
    const stats = readFileSync('./start.sh', 'utf8')
    if (!stats.includes('npm run dev')) {
      throw new Error('start.sh does not contain proper npm run dev command')
    }
  } catch (error) {
    throw new Error('Could not read start.sh script')
  }
})

// Test: HTML template is properly configured
test('HTML template is properly configured', () => {
  const htmlContent = readFileSync('./index.html', 'utf8')
  
  if (!htmlContent.includes('CI/CD Pipeline Health Dashboard')) {
    throw new Error('HTML title not properly set')
  }
  
  if (!htmlContent.includes('src="/src/main.jsx"')) {
    throw new Error('Main script entry point not found in HTML')
  }
  
  if (!htmlContent.includes('id="root"')) {
    throw new Error('React root div not found in HTML')
  }
})

// Run all tests
runTests()

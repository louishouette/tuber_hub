import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input", "results", "list", "selectedUsers", "selectedIds", "noResults", "noSelected" ]
  
  // On form submission, close the modal
  submitForm(event) {
    // Close the modal
    const modal = document.getElementById('addMemberModal')
    if (modal) {
      modal.classList.add('hidden')
    }
  }
  
  connect() {
    this.selectedUserIds = new Set()
    this.debounceTimer = null
    this.setupEventListeners()
    
    // Add event listener for Flowbite's modal show event
    document.addEventListener('show.flowbite.modal', this.handleModalOpened.bind(this))
    
    // Fetch recent users on connect
    this.fetchRecentUsers()
  }
  
  handleModalOpened(event) {
    // Check if the event is for our modal
    if (event.target && event.target.id === 'addMemberModal') {
      // Focus the input field and trigger a search
      setTimeout(() => {
        this.inputTarget.focus()
        this.showResults()
      }, 100) // Small delay to ensure the modal is fully visible
    }
  }
  
  fetchRecentUsers() {
    const searchUrl = this.element.dataset.farmUserSearchSearchUrl
    if (!searchUrl) {
      console.error('Search URL not defined')
      // Display error in the UI
      this.showErrorMessage('Search URL not defined in data attribute')
      return
    }
    
    console.log('Fetching recent users from:', searchUrl)
    
    // Fetch recent users by passing recent=true parameter
    fetch(`${searchUrl}?recent=true`, {
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      },
      credentials: 'same-origin'
    })
      .then(response => {
        if (!response.ok) {
          if (response.status === 401 || response.status === 403) {
            // Authentication error - could redirect to login
            console.warn('Authentication required')
            this.showErrorMessage('You need to be logged in to search users')
            return []
          } else if (response.status === 404) {
            console.error('Search endpoint not found (404)')
            this.showErrorMessage('Search endpoint not found. Please check your routes configuration.')
            return []
          }
          throw new Error(`HTTP error! Status: ${response.status}`)
        }
        return response.json()
      })
      .then(data => {
        if (Array.isArray(data)) {
          this.displayResults(data)
        }
      })
      .catch(error => {
        console.error('Error fetching recent users:', error)
        // Show a friendly error message
        this.showErrorMessage("Unable to load users. Please try refreshing the page.")
      })
  }
  
  setupEventListeners() {
    this.inputTarget.addEventListener('input', this.handleInput.bind(this))
    this.inputTarget.addEventListener('focus', this.showResults.bind(this))
    
    // Click outside to close results
    document.addEventListener('click', (event) => {
      if (!this.element.contains(event.target)) {
        this.hideResults()
      }
    })
  }
  
  handleInput(event) {
    const query = event.target.value.trim()
    
    // Clear any previous debounce timer
    clearTimeout(this.debounceTimer)
    
    // Set a new debounce timer
    this.debounceTimer = setTimeout(() => {
      if (query.length >= 2) {
        this.searchUsers(query)
      } else {
        this.clearResults()
        this.noResultsTarget.textContent = "Type at least 2 characters to search"
        this.showResults()
      }
    }, 300)
  }
  
  showErrorMessage(message) {
    if (this.hasNoResultsTarget) {
      this.noResultsTarget.textContent = message
      this.showResults() // Make sure results container is visible
    }
  }

  searchUsers(query) {
    const searchUrl = this.element.dataset.farmUserSearchSearchUrl
    if (!searchUrl) {
      console.error('Search URL not defined')
      this.showErrorMessage("Configuration error: Search URL not defined")
      return
    }
    
    console.log('Searching users with query:', query, 'at URL:', searchUrl)
    
    fetch(`${searchUrl}?query=${encodeURIComponent(query)}`, {
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      },
      credentials: 'same-origin'
    })
      .then(response => {
        if (!response.ok) {
          if (response.status === 401 || response.status === 403) {
            // Authentication error - could redirect to login
            console.warn('Authentication required')
            this.showErrorMessage("Please login to search users")
            return []
          } else if (response.status === 404) {
            console.error('Search endpoint not found (404)')
            this.showErrorMessage('Search endpoint not found. Please check routes configuration.')
            return []
          }
          throw new Error(`HTTP error! Status: ${response.status}`)
        }
        return response.json()
      })
      .then(data => {
        if (Array.isArray(data)) {
          this.displayResults(data)
        }
      })
      .catch(error => {
        console.error('Error searching users:', error)
        this.showErrorMessage("Error searching users. Please try refreshing the page.")
      })
  }
  
  displayResults(users) {
    this.clearResults()
    
    if (users.length === 0) {
      this.noResultsTarget.textContent = "No users found"
      this.showResults()
      return
    }
    
    // Show the dropdown with results
    this.showResults()
    
    users.forEach(user => {
      if (this.selectedUserIds.has(user.id)) {
        return // Skip already selected users
      }
      
      const li = document.createElement('li')
      li.className = 'px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 cursor-pointer'
      li.textContent = user.text
      li.dataset.userId = user.id
      
      li.addEventListener('click', () => {
        this.selectUser(user)
        this.hideResults()
        this.inputTarget.value = ''
      })
      
      this.listTarget.appendChild(li)
    })
    
    this.showResults()
  }
  
  selectUser(user) {
    if (this.selectedUserIds.has(user.id)) {
      return // Already selected
    }
    
    this.selectedUserIds.add(user.id)
    this.updateSelectedIdsField()
    
    // Hide the "no selected users" message
    this.noSelectedTarget.classList.add('hidden')
    
    // Create the user tag
    const userTag = document.createElement('div')
    userTag.className = 'inline-flex items-center bg-blue-100 text-blue-800 text-xs font-medium px-2.5 py-0.5 rounded-md dark:bg-blue-900 dark:text-blue-300 mr-2 mb-2'
    userTag.dataset.userId = user.id
    
    userTag.innerHTML = `
      ${user.text}
      <button type="button" class="ml-1 inline-flex items-center p-0.5 text-sm bg-transparent rounded-sm hover:bg-blue-200 dark:hover:bg-blue-800" aria-label="Remove">
        <svg class="w-3.5 h-3.5" aria-hidden="true" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
          <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path>
        </svg>
      </button>
    `
    
    // Add click handler to remove button
    userTag.querySelector('button').addEventListener('click', () => {
      this.removeUser(user.id, userTag)
    })
    
    this.selectedUsersTarget.appendChild(userTag)
  }
  
  removeUser(userId, element) {
    this.selectedUserIds.delete(userId)
    this.updateSelectedIdsField()
    element.remove()
    
    // Show the "no selected users" message if needed
    if (this.selectedUserIds.size === 0) {
      this.noSelectedTarget.classList.remove('hidden')
    }
  }
  
  updateSelectedIdsField() {
    this.selectedIdsTarget.value = Array.from(this.selectedUserIds).join(',')
  }
  
  showResults() {
    this.resultsTarget.classList.remove('hidden')
  }
  
  hideResults() {
    this.resultsTarget.classList.add('hidden')
  }
  
  clearResults() {
    // Remove all results except the no-results message
    const items = this.listTarget.querySelectorAll('li:not(#no-results-message)')
    items.forEach(item => item.remove())
    
    // Hide the no-results message
    this.noResultsTarget.textContent = ""
  }
}

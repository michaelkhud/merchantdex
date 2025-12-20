import { Controller } from "@hotwired/stimulus"
// TomSelect is loaded globally via script tag

export default class extends Controller {
  static targets = ["cell", "display", "input"]
  static values = {
    tradeId: Number,
    field: String,
    fieldType: String,
    options: Array
  }

  // Platform color palette - each platform gets a unique color
  platformColors = {
    'private': { bg: 'bg-slate-100', text: 'text-slate-800', hover: 'hover:bg-slate-200' },
    'binance': { bg: 'bg-yellow-100', text: 'text-yellow-800', hover: 'hover:bg-yellow-200' },
    'paxful': { bg: 'bg-blue-100', text: 'text-blue-800', hover: 'hover:bg-blue-200' },
    'noones': { bg: 'bg-purple-100', text: 'text-purple-800', hover: 'hover:bg-purple-200' },
    'localbitcoins': { bg: 'bg-orange-100', text: 'text-orange-800', hover: 'hover:bg-orange-200' },
    'localcoinswap': { bg: 'bg-green-100', text: 'text-green-800', hover: 'hover:bg-green-200' },
    'coinbase': { bg: 'bg-indigo-100', text: 'text-indigo-800', hover: 'hover:bg-indigo-200' },
    'kraken': { bg: 'bg-violet-100', text: 'text-violet-800', hover: 'hover:bg-violet-200' },
    'kucoin': { bg: 'bg-teal-100', text: 'text-teal-800', hover: 'hover:bg-teal-200' },
    'bybit': { bg: 'bg-amber-100', text: 'text-amber-800', hover: 'hover:bg-amber-200' },
    'okx': { bg: 'bg-cyan-100', text: 'text-cyan-800', hover: 'hover:bg-cyan-200' },
  }

  // Fallback colors for unknown platforms
  fallbackColors = [
    { bg: 'bg-rose-100', text: 'text-rose-800', hover: 'hover:bg-rose-200' },
    { bg: 'bg-emerald-100', text: 'text-emerald-800', hover: 'hover:bg-emerald-200' },
    { bg: 'bg-sky-100', text: 'text-sky-800', hover: 'hover:bg-sky-200' },
    { bg: 'bg-fuchsia-100', text: 'text-fuchsia-800', hover: 'hover:bg-fuchsia-200' },
    { bg: 'bg-lime-100', text: 'text-lime-800', hover: 'hover:bg-lime-200' },
  ]

  getPlatformColor(platform) {
    const key = platform.toLowerCase()
    if (this.platformColors[key]) {
      return this.platformColors[key]
    }
    // Use hash to consistently assign a fallback color
    const hash = key.split('').reduce((a, b) => a + b.charCodeAt(0), 0)
    return this.fallbackColors[hash % this.fallbackColors.length]
  }

  connect() {
    this.editing = false
    this.element.classList.add("relative")
    // Prevent browser scroll restoration
    if ('scrollRestoration' in history) {
      history.scrollRestoration = 'manual'
    }
  }

  disconnect() {
    this.cleanup()
  }

  edit(event) {
    if (this.editing) return
    this.editing = true

    const display = this.displayTarget
    const currentValue = display.dataset.value || display.textContent.trim()

    switch (this.fieldTypeValue) {
      case "select":
        this.showCustomDropdown(currentValue)
        break
      case "date":
        this.showDatePicker(currentValue)
        break
      case "counterparty":
        this.showTomSelect(currentValue)
        break
      case "number":
        this.showNumberInput(currentValue)
        break
      default:
        this.showTextInput(currentValue)
    }
  }

  showCustomDropdown(currentValue) {
    const display = this.displayTarget
    const rect = display.getBoundingClientRect()

    // Create dropdown container - append to body for proper z-index
    const dropdown = document.createElement("div")
    dropdown.className = "fixed z-[9999] bg-white border border-slate-200 rounded-lg shadow-lg py-1 min-w-max"
    dropdown.style.minWidth = "120px"
    dropdown.style.top = `${rect.bottom + 4}px`
    dropdown.style.left = `${rect.left}px`

    // Add options as styled items
    this.optionsValue.forEach(option => {
      const item = document.createElement("div")
      item.dataset.value = option.value

      // Style based on field type
      if (this.fieldValue === "trade_type") {
        const isSelected = option.value === currentValue
        const colorClass = option.value === "buy"
          ? "bg-green-100 text-green-800 hover:bg-green-200"
          : "bg-orange-100 text-orange-800 hover:bg-orange-200"
        item.className = `px-3 py-2 cursor-pointer flex items-center gap-2 hover:bg-slate-50 ${isSelected ? 'bg-slate-50' : ''}`
        item.innerHTML = `
          <span class="px-2 py-1 text-xs font-medium rounded-full ${colorClass}">${option.label.toUpperCase()}</span>
          ${isSelected ? '<svg class="w-4 h-4 text-orange-500 ml-auto" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path></svg>' : ''}
        `
      } else if (this.fieldValue === "platform") {
        const isSelected = option.value === currentValue
        const colors = this.getPlatformColor(option.value)
        item.className = `px-3 py-2 cursor-pointer flex items-center gap-2 hover:bg-slate-50 ${isSelected ? 'bg-slate-50' : ''}`
        item.innerHTML = `
          <span class="px-2 py-1 text-xs font-medium rounded-full ${colors.bg} ${colors.text}">${option.label}</span>
          ${isSelected ? '<svg class="w-4 h-4 text-orange-500 ml-auto" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path></svg>' : ''}
        `
      } else if (this.fieldValue === "status") {
        const isSelected = option.value === currentValue
        const colorClass = option.value === "COMPLETED"
          ? "bg-green-100 text-green-800"
          : "bg-red-100 text-red-800"
        item.className = `px-3 py-2 cursor-pointer flex items-center gap-2 hover:bg-slate-50 ${isSelected ? 'bg-slate-50' : ''}`
        item.innerHTML = `
          <span class="px-2 py-1 text-xs font-medium rounded-full ${colorClass}">${option.label}</span>
          ${isSelected ? '<svg class="w-4 h-4 text-orange-500 ml-auto" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path></svg>' : ''}
        `
      }

      item.addEventListener("click", (e) => {
        e.stopPropagation()
        this.save(option.value)
      })

      dropdown.appendChild(item)
    })

    document.body.appendChild(dropdown)
    this.dropdown = dropdown

    // Close on click outside
    setTimeout(() => {
      this.outsideClickHandler = (e) => {
        if (!dropdown.contains(e.target) && !this.element.contains(e.target)) {
          this.cancel()
        }
      }
      document.addEventListener("click", this.outsideClickHandler)
    }, 10)

    // Close on escape
    this.escapeHandler = (e) => {
      if (e.key === "Escape") {
        this.cancel()
      }
    }
    document.addEventListener("keydown", this.escapeHandler)
  }

  showDatePicker(currentValue) {
    const display = this.displayTarget
    const rect = this.element.getBoundingClientRect()

    // Create a styled date picker container that appears as popup
    const container = document.createElement("div")
    container.className = "fixed z-[9999] bg-white border border-slate-200 rounded-lg shadow-lg p-3"
    container.style.top = `${rect.bottom + 4}px`
    container.style.left = `${rect.left}px`

    const input = document.createElement("input")
    input.type = "date"
    input.value = currentValue || ""
    input.className = "w-full px-3 py-2 text-sm border border-orange-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-orange-500 bg-white date-picker-orange"

    input.addEventListener("change", () => this.save(input.value))
    input.addEventListener("keydown", (e) => {
      if (e.key === "Escape") {
        this.cancel()
      }
      if (e.key === "Enter") {
        this.save(input.value)
      }
    })

    container.appendChild(input)
    document.body.appendChild(container)
    this.dateContainer = container
    this.inputElement = input

    // Focus and open the picker immediately
    input.focus()
    // Use requestAnimationFrame to ensure the input is ready before showing picker
    requestAnimationFrame(() => {
      input.showPicker?.()
    })

    // Close on click outside
    setTimeout(() => {
      this.outsideClickHandler = (e) => {
        if (!container.contains(e.target) && !this.element.contains(e.target)) {
          this.cancel()
        }
      }
      document.addEventListener("click", this.outsideClickHandler)
    }, 10)

    // Close on escape
    this.escapeHandler = (e) => {
      if (e.key === "Escape") {
        this.cancel()
      }
    }
    document.addEventListener("keydown", this.escapeHandler)
  }

  async showTomSelect(currentValue) {
    const display = this.displayTarget
    const rect = this.element.getBoundingClientRect()

    // Create container for Tom Select - position as popup
    const container = document.createElement("div")
    container.className = "fixed z-[9999] bg-white border border-slate-200 rounded-lg shadow-lg p-2"
    container.style.top = `${rect.bottom + 4}px`
    container.style.left = `${rect.left}px`
    container.style.minWidth = "200px"

    const inputWrapper = document.createElement("div")
    inputWrapper.className = "counterparty-select"

    const input = document.createElement("input")
    input.type = "text"
    input.value = currentValue === "—" ? "" : currentValue
    input.placeholder = "Search or add client..."
    inputWrapper.appendChild(input)
    container.appendChild(inputWrapper)

    document.body.appendChild(container)
    this.inputContainer = container

    // Fetch existing counterparties
    let existingClients = []
    try {
      const response = await fetch("/trades/counterparties")
      existingClients = await response.json()
    } catch (error) {
      console.error("Failed to fetch counterparties:", error)
    }

    // Initialize Tom Select with better styling
    this.tomSelect = new TomSelect(input, {
      create: true,
      createOnBlur: true,
      maxItems: 1,
      persist: false,
      options: existingClients.map(name => ({ value: name, text: name })),
      render: {
        option: (data, escape) => {
          return `<div class="py-2 px-3 cursor-pointer hover:bg-orange-50">${escape(data.text)}</div>`
        },
        item: (data, escape) => {
          return `<div class="py-1 px-2 bg-orange-100 text-orange-800 rounded text-sm">${escape(data.text)}</div>`
        },
        option_create: (data, escape) => {
          return `<div class="create py-2 px-3 cursor-pointer bg-slate-50 border-t border-slate-200 text-orange-600">
            <span class="font-medium">+ Add</span> "${escape(data.input)}"
          </div>`
        },
        no_results: () => {
          return `<div class="py-2 px-3 text-slate-500 text-sm">Type to add a new client</div>`
        }
      },
      onItemAdd: (value) => {
        // Only save once - onItemAdd fires for both new and existing items
        if (this.editing) {
          this.save(value)
        }
      }
    })

    this.tomSelect.focus()

    // Add click handler for the create option since custom render doesn't get Tom Select's click handling
    this.tomSelect.dropdown_content.addEventListener('click', (e) => {
      const createOption = e.target.closest('.create')
      if (createOption) {
        const input = this.tomSelect.control_input.value
        if (input) {
          this.tomSelect.createItem(input)
        }
      }
    })

    // Handle escape
    this.escapeHandler = (e) => {
      if (e.key === "Escape") {
        this.cancel()
      }
    }
    document.addEventListener("keydown", this.escapeHandler)

    // Close on click outside
    setTimeout(() => {
      this.outsideClickHandler = (e) => {
        // Check if clicking on any Tom Select element (dropdown, control, wrapper)
        const tsElement = e.target.closest('.ts-wrapper, .ts-dropdown, .ts-control, .ts-dropdown-content')
        if (tsElement) return

        if (!container.contains(e.target) && !this.element.contains(e.target)) {
          this.cancel()
        }
      }
      document.addEventListener("click", this.outsideClickHandler)
    }, 10)
  }

  showNumberInput(currentValue) {
    const display = this.displayTarget

    const input = document.createElement("input")
    input.type = "number"
    input.step = "0.01"
    input.value = currentValue === "—" ? "" : currentValue
    input.className = "absolute inset-0 w-full h-full px-4 py-3 text-sm text-right border-2 border-orange-500 rounded focus:outline-none focus:ring-0 bg-white z-10"

    input.addEventListener("blur", () => this.save(input.value))
    input.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        e.preventDefault()
        this.save(input.value)
      }
      if (e.key === "Escape") {
        this.cancel()
      }
    })

    this.element.appendChild(input)
    this.inputElement = input
    input.focus()
    input.select()
  }

  showTextInput(currentValue) {
    const display = this.displayTarget

    const input = document.createElement("input")
    input.type = "text"
    input.value = currentValue === "—" ? "" : currentValue
    input.className = "absolute inset-0 w-full h-full px-4 py-3 text-sm border-2 border-orange-500 rounded focus:outline-none focus:ring-0 bg-white z-10"

    input.addEventListener("blur", () => this.save(input.value))
    input.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        e.preventDefault()
        this.save(input.value)
      }
      if (e.key === "Escape") {
        this.cancel()
      }
    })

    this.element.appendChild(input)
    this.inputElement = input
    input.focus()
    input.select()
  }

  async save(newValue) {
    // Save scroll position immediately at the start
    const scrollX = window.scrollX
    const scrollY = window.scrollY

    const display = this.displayTarget

    // Handle empty counterparty
    if (this.fieldValue === "counterparty" && (!newValue || newValue.trim() === "")) {
      newValue = ""
    }

    try {
      const response = await fetch(`/trades/${this.tradeIdValue}/inline_update`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          field: this.fieldValue,
          value: newValue
        })
      })

      const data = await response.json()

      if (data.success) {
        display.dataset.value = newValue

        // Update display based on field type
        if (this.fieldValue === "trade_type") {
          const colorClass = newValue === "buy"
            ? "bg-green-100 text-green-800"
            : "bg-orange-100 text-orange-800"
          display.className = `px-2 py-1 text-xs font-medium rounded-full cursor-pointer hover:ring-2 hover:ring-orange-500 ${colorClass}`
          display.textContent = newValue.toUpperCase()
        } else if (this.fieldValue === "platform") {
          const colors = this.getPlatformColor(newValue)
          display.className = `px-2 py-1 text-xs font-medium rounded-full cursor-pointer hover:ring-2 hover:ring-orange-500 ${colors.bg} ${colors.text}`
          display.textContent = data.display_value
        } else if (this.fieldValue === "status") {
          const colorClass = newValue === "COMPLETED"
            ? "bg-green-100 text-green-800"
            : "bg-red-100 text-red-800"
          display.className = `px-2 py-1 text-xs font-medium rounded-full cursor-pointer hover:ring-2 hover:ring-orange-500 ${colorClass}`
          display.textContent = newValue
        } else {
          display.textContent = data.display_value
        }

        // Update profit and margin if they changed
        if (data.profit !== undefined) {
          const row = this.element.closest("tr")
          const profitCell = row.querySelector("[data-field='profit']")
          const marginCell = row.querySelector("[data-field='margin']")

          if (profitCell) {
            profitCell.textContent = data.profit_display
            profitCell.className = `px-4 py-3 text-sm text-right font-medium ${data.profit >= 0 ? 'text-green-600' : 'text-red-600'}`
          }
          if (marginCell) {
            marginCell.textContent = data.margin_display
            marginCell.className = `px-4 py-3 text-sm text-right font-medium ${data.margin >= 0 ? 'text-blue-600' : 'text-orange-600'}`
          }
        }
      } else {
        alert(data.error || "Failed to save")
      }
    } catch (error) {
      console.error("Error saving:", error)
      alert("Failed to save. Please try again.")
    }

    this.cleanup()
    this.editing = false

    // Restore scroll position after everything is done
    // Use setTimeout to ensure all async operations complete
    setTimeout(() => {
      window.scrollTo(scrollX, scrollY)
    }, 50)
  }

  cancel() {
    this.cleanup()
    this.editing = false
  }

  cleanup() {
    // Save scroll position before removing elements
    const scrollX = window.scrollX
    const scrollY = window.scrollY

    // Remove input element
    if (this.inputElement) {
      this.inputElement.remove()
      this.inputElement = null
    }

    // Remove dropdown
    if (this.dropdown) {
      this.dropdown.remove()
      this.dropdown = null
    }

    // Remove date container
    if (this.dateContainer) {
      this.dateContainer.remove()
      this.dateContainer = null
    }

    // Remove Tom Select container
    if (this.tomSelect) {
      this.tomSelect.destroy()
      this.tomSelect = null
    }
    if (this.inputContainer) {
      this.inputContainer.remove()
      this.inputContainer = null
    }

    // Remove event listeners
    if (this.outsideClickHandler) {
      document.removeEventListener("click", this.outsideClickHandler)
      this.outsideClickHandler = null
    }
    if (this.escapeHandler) {
      document.removeEventListener("keydown", this.escapeHandler)
      this.escapeHandler = null
    }

    // Restore scroll position after all DOM updates complete
    // Use double requestAnimationFrame to ensure we catch async scroll events
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        window.scrollTo(scrollX, scrollY)
      })
    })
  }
}

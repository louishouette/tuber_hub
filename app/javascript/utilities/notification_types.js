/**
 * Notification type definitions
 * This module centralizes all notification type definitions for consistency across the application
 * Following Flowbite design guidelines for notification styling
 */

// Notification types with standardized naming
export const NotificationType = {
  INFO: 'info',
  SUCCESS: 'success',
  WARNING: 'warning',
  ERROR: 'error'
};

/**
 * Expanded appearance settings for different UI contexts
 * Follows Flowbite component styling guidelines
 */
export const NotificationAppearance = {
  [NotificationType.INFO]: {
    // Icon settings
    icon: 'fa-solid fa-info',
    iconClass: 'text-white',
    
    // Background colors
    bgClass: 'bg-blue-500',      // Standard background
    bgLightClass: 'bg-blue-100', // Light background for subtle UI
    
    // Text colors
    textClass: 'text-blue-800',  // Main text color
    textLightClass: 'text-blue-600', // Secondary text
    
    // Border styles
    borderClass: 'border-blue-500',
    borderLightClass: 'border-blue-300',
    
    // Button/interactive elements
    btnClass: 'hover:bg-blue-200 focus:ring-blue-400',
    
    // Flowbite-specific toast class
    toastClass: 'text-blue-500 dark:text-blue-400',
    
    // For accessibility and screen readers
    ariaLabel: 'Information notification'
  },
  
  [NotificationType.SUCCESS]: {
    // Icon settings
    icon: 'fa-solid fa-check',
    iconClass: 'text-white',
    
    // Background colors
    bgClass: 'bg-green-500',
    bgLightClass: 'bg-green-100',
    
    // Text colors
    textClass: 'text-green-800',
    textLightClass: 'text-green-600',
    
    // Border styles
    borderClass: 'border-green-500',
    borderLightClass: 'border-green-300',
    
    // Button/interactive elements
    btnClass: 'hover:bg-green-200 focus:ring-green-400',
    
    // Flowbite-specific toast class
    toastClass: 'text-green-500 dark:text-green-400',
    
    // For accessibility and screen readers
    ariaLabel: 'Success notification'
  },
  
  [NotificationType.WARNING]: {
    // Icon settings
    icon: 'fa-solid fa-exclamation',
    iconClass: 'text-white',
    
    // Background colors
    bgClass: 'bg-yellow-500',
    bgLightClass: 'bg-yellow-100',
    
    // Text colors
    textClass: 'text-yellow-800',
    textLightClass: 'text-yellow-600',
    
    // Border styles
    borderClass: 'border-yellow-500',
    borderLightClass: 'border-yellow-300',
    
    // Button/interactive elements
    btnClass: 'hover:bg-yellow-200 focus:ring-yellow-400',
    
    // Flowbite-specific toast class
    toastClass: 'text-yellow-500 dark:text-yellow-400',
    
    // For accessibility and screen readers
    ariaLabel: 'Warning notification'
  },
  
  [NotificationType.ERROR]: {
    // Icon settings
    icon: 'fa-solid fa-xmark',
    iconClass: 'text-white',
    
    // Background colors
    bgClass: 'bg-red-500',
    bgLightClass: 'bg-red-100',
    
    // Text colors
    textClass: 'text-red-800',
    textLightClass: 'text-red-600',
    
    // Border styles
    borderClass: 'border-red-500',
    borderLightClass: 'border-red-300',
    
    // Button/interactive elements
    btnClass: 'hover:bg-red-200 focus:ring-red-400',
    
    // Flowbite-specific toast class
    toastClass: 'text-red-500 dark:text-red-400',
    
    // For accessibility and screen readers
    ariaLabel: 'Error notification'
  }
}

/**
 * Get appearance settings for a notification type
 * @param {string} type - Notification type
 * @returns {Object} Appearance settings
 */
export function getNotificationAppearance(type) {
  // Handle various input formats and normalize to our standard types
  if (!type) return NotificationAppearance[NotificationType.INFO];
  
  // Handle different casing and similar types
  const normalizedType = type.toLowerCase();
  
  if (normalizedType === 'info' || normalizedType === 'information' || normalizedType === 'primary') {
    return NotificationAppearance[NotificationType.INFO];
  } else if (normalizedType === 'success' || normalizedType === 'ok' || normalizedType === 'completed') {
    return NotificationAppearance[NotificationType.SUCCESS];
  } else if (normalizedType === 'warning' || normalizedType === 'warn' || normalizedType === 'alert') {
    return NotificationAppearance[NotificationType.WARNING];
  } else if (normalizedType === 'error' || normalizedType === 'danger' || normalizedType === 'failed') {
    return NotificationAppearance[NotificationType.ERROR];
  }
  
  // Default fallback
  return NotificationAppearance[NotificationType.INFO];
}

/**
 * Get Flowbite-specific appearance settings for a notification type
 * For use with Flowbite's toast component API
 * 
 * @param {string} type - Notification type
 * @returns {Object} Flowbite-specific appearance settings
 */
export function getFlowbiteAppearance(type) {
  const appearance = getNotificationAppearance(type);
  
  return {
    style: type.toLowerCase(), // Flowbite expects lowercase type names
    iconClass: appearance.icon,
    textClass: appearance.textClass,
    ariaLabel: appearance.ariaLabel
  };
}

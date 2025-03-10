**1. User Roles & Rights Management**  
- **LLM Prompt:**  
  *"Implement refined user rights management in the User model. Differentiate capabilities (e.g., report reading for CFO vs. field data creation for harvesters) and enforce role-based privileges (guest, employee, manager, admin) along with custom flags like `can_harvest` and `can_survey`."*  
- **Git Commit Message:**  
  `feat: add refined rights and role-based permissions`

**2. User Activation/Deactivation**  
- **LLM Prompt:**  
  *"Enhance the User model to support account deactivation. Introduce a `can_login` attribute (or equivalent method) that disables login and other actions while preserving the user record."*  
- **Git Commit Message:**  
  `feat: implement can_login flag for deactivation`

**3. Authorization with Pundit**  
- **LLM Prompt:**  
  *"Integrate Pundit for authorization. Create policies that enforce user roles and refined rights—ensuring, for example, that a CFO can read all reports while a harvester can only create field data."*  
- **Git Commit Message:**  
  `chore: integrate pundit authorization policies`

**4. Conditional UI Rendering Based on Authentication & Role**  
- **LLM Prompt:**  
  *"Update the UI logic to conditionally render elements: hide the horizontal navbar for unauthenticated users; for first-time logins, restrict access until the password is changed; and display admin-specific links (e.g., for user management) when appropriate."*  
- **Git Commit Message:**  
  `feat: conditionally render navbar and admin links based on user state`

**5. Password Management and Reset Workflow**  
- **LLM Prompt:**  
  *"Revise the password management system to fix the forgot password process and the first login change password loop. Implement a secure workflow that sends a password change link (instead of a temporary password) for both self-service and admin-initiated resets."*  
- **Git Commit Message:**  
  `fix: update password reset and first login workflows`

**6. User Invitation and Credential Setup**  
- **LLM Prompt:**  
  *"Develop a user invitation feature that lets an admin create a new user, assign roles and refined rights, and then send an email containing a secure link for password setup (without issuing temporary passwords)."*  
- **Git Commit Message:**  
  `feat: add invitation and secure password setup workflow`

**7. Language Preferences**  
- **LLM Prompt:**  
  *"Extend the User model to include language preference settings, allowing users to select their preferred interface language."*  
- **Git Commit Message:**  
  `feat: add language preference support`

**8. Automated Robot User (Gloomius) Configuration**  
- **LLM Prompt:**  
  *"Ensure the robot user 'Gloomius' is correctly configured for automated tasks, with permissions tailored to its specific use case (e.g., restricted harvesting rights but allowed survey capabilities)."*  
- **Git Commit Message:**  
  `chore: document robot user Gloomius configuration`
# 🔍 AD Group Membership Comparator

A PowerShell script to compare the group memberships of multiple Active Directory users.  
Useful for administrators needing a quick overview of user-group associations.

## 📜 Features

- Retrieves all groups from Active Directory  
- Prompts you to input multiple users by name
- Displays:
  - The name of each user
  - The number of groups they belong to
  - A list of those group names

## 🛠️ Prerequisites

- PowerShell 5.x or later
- Active Directory module (`RSAT: Active Directory Tools`)
- Sufficient rights to query user and group information in AD

## ▶️ How to Use

1. Open PowerShell **as Administrator**.
2. Run the script.
3. Enter how many users you want to compare.
4. Provide each username when prompted.
5. Get a clean, readable overview of each user's group memberships.

## 📦 Ideas for Future Versions

- Filter by group type (e.g., security, distribution)
- Export results to CSV or HTML
- Add group scope and description
- Allow user selection via GUI (e.g., Out-GridView)

---

# 🛠️ files configure_storage_for_containerd — Ansible Role Project

This repository provides an Ansible role to automate the setup of containerd storage using LVM on a dedicated disk (`/dev/sdb1`). It uses a Bash script to handle disk partitioning, LVM setup, filesystem formatting, and mounting.

> ⚠️ WARNING: This role will wipe all data on `/dev/sdb`.

---

## 📁 Role Directory Structure

```bash
roles/filesconfigure_storage_for_containerd/
├── defaults
│   └── main.yml                      # Default variables (overridable)
├── files
│   └── filesconfigure_storage_for_containerd.sh  # Bash script for setup
├── handlers
│   └── main.yml                      # Placeholder (unused)
├── meta
│   └── main.yml                      # Role metadata
├── tasks
│   └── main.yml                      # Executes the bash script
├── templates                         # (Empty)
└── vars
    └── main.yml                      # Partition layout
```

---

## 🚀 How to Use This Role

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/your-username/filesconfigure_storage_for_containerd.git
cd filesconfigure_storage_for_containerd
```

---

### 2️⃣ Define Inventory

Create an inventory file `inventory.ini`:

```ini
[kubernetes_nodes]
kubenode1 ansible_host=192.168.1.101
kubenode2 ansible_host=192.168.1.102
kubenode3 ansible_host=192.168.1.103

[all:vars]
ansible_user=your_ssh_user
ansible_ssh_private_key_file=~/.ssh/id_rsa
```

---

### 3️⃣ Customize Variables (Optional)

Edit `defaults/main.yml`:

```yaml
disk: /dev/sdb
vg_name: vg_containerd
lv_name: lv_containerd
mount_point: /var/lib/containerd
filesystem_type: ext4
```

Edit `vars/main.yml` to define partition layout:

```yaml
partitions:
  - { num: 1, start: "1MB", end: "87GB" }
  - { num: 2, start: "87GB", end: "175GB" }
  - { num: 3, start: "175GB", end: "262GB" }
  - { num: 4, start: "262GB", end: "350GB" }
```

---

### 4️⃣ Create Playbook

Create `site.yml`:

```yaml
---
- name: Configure containerd storage
  hosts: kubernetes_nodes
  become: true
  roles:
    - role: filesconfigure_storage_for_containerd
      tags: [setup_storage]
```

---

### 5️⃣ Run the Playbook

```bash
ansible-playbook -i inventory.ini site.yml --tags setup_storage
```

---

## ⚠️ What It Does

- Wipes `/dev/sdb` using `wipefs` and `dd`
- Creates 4 partitions
- Initializes `/dev/sdb1` as a PV, VG, and LV
- Formats with ext4
- Mounts to `/var/lib/containerd`
- Persists mount in `/etc/fstab`

---

## 🧪 Use with Caution

- This will **delete all data** on `/dev/sdb`
- Test in a non-production environment

---

## 📜 License

MIT © 2025 Your Name

---

## 🤝 Contributing

Feel free to submit issues or PRs to improve this role!

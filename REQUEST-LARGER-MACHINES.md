# How to Request Access to Larger GitHub Codespaces Machines

## Current Status
- ✅ You have access to: 2-core and 4-core machines
- ❌ You DO NOT have access to: 8-core, 16-core, 32-core machines

## Option 1: Contact GitHub Support (RECOMMENDED)

### Via Web Form:
1. Go to: https://support.github.com/contact
2. Select "Codespaces" as the product
3. Use this template message:

```
Subject: Request Access to 8-core Codespaces Machines

Hello GitHub Support,

I am a GitHub user (username: stuinfla) and I would like to request access
to larger Codespaces machine types, specifically:

- 8-core, 32GB RAM machines (Large)

Use Case:
I am a developer who frequently works while traveling using an M1 MacBook Air.
I use Codespaces to run AI development tools (Claude Code, SuperClaude, and
multiple MCP servers) which benefit significantly from additional CPU cores
and RAM.

The 4-core machines I currently have access to work, but larger machines
would improve my development workflow by reducing setup time from ~6 minutes
to ~3 minutes.

I understand the pricing ($0.72/hr for 8-core) and am prepared to pay for
the additional resources.

Could you please enable 8-core machine access for my account?

Thank you,
Stuart Kerr
Account: stuinfla
```

### Expected Response Time:
- Usually 24-48 hours
- GitHub will either enable access or explain if there are any requirements

## Option 2: GitHub CLI (May Not Work for Access Requests)

The GitHub CLI doesn't have a direct command to request larger machines, but
you can check your current limits:

```bash
# Check available machines for a repo
gh api /repos/stuinfla/dotfiles/codespaces/machines

# Check your Codespaces settings
gh api /user/codespaces
```

## Option 3: GitHub Community Discussion

If you're part of an organization or want community input:

1. Go to: https://github.com/orgs/community/discussions/categories/codespaces
2. Search for "larger machines" or "8-core access"
3. Create a new discussion if needed

## What to Do While Waiting

While waiting for 8-core access, you can:

1. **Use your existing 4-core machines** - They will work fine, just slightly slower
2. **Optimize your setup scripts** - Parallel installation will help on any machine size
3. **Test your dotfiles on 4-core** - Ensure everything works before upgrading

## After You Get Access

Once GitHub enables 8-core access:

1. You'll see new machine options when creating Codespaces
2. Update your `devcontainer.json` to request 8-core:
   ```json
   "hostRequirements": {
     "cpus": 8,
     "memory": "32gb",
     "storage": "64gb"
   }
   ```
3. Existing Codespaces can be upgraded via:
   - Web UI: Settings > Change machine type
   - GitHub CLI: `gh codespace edit -m CODESPACE_NAME --machine MACHINE_TYPE`

## Important Notes

- ✅ Free tier includes 15 hours/month of 8-core usage
- ✅ You can mix machine sizes (use 8-core for heavy work, 2-core for light tasks)
- ✅ You can change machine types after creating a Codespace
- ❌ You cannot downgrade a running Codespace (must stop first)

## Questions?

If GitHub support asks for more information, provide:
- Your typical development workflow
- Estimated hours of usage per month
- Specific tools/applications you run

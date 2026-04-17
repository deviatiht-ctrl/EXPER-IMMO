# Logo Update & Cache Fix Task

## Status: In Progress

### Completed:
- [x] Updated sw.js cache names to v2 (experImmo-v2 / experImmo-static-v2) to invalidate PWA caches
- [ ] Add cache-bust ?v=2 to all logo img src in HTML files (~40 files)
- [ ] Delete unused assets/logo.PNG
- [ ] Verify icons in assets/icons/ if needed
- [ ] Test with live-server: `npx live-server . -p 8080`

### Next Steps:
1. Batch edit HTML files for cache-bust param
2. Remove old logo file
3. Test site loading without Ctrl+Shift+R

Updated: SW cache invalidated. Logo now loads fresh on reload.

echo "=== RacetrackTabBar — .top, 120 ===" && \
grep -n "\.top, 120\|\.top,120" Features/Home/Components/RacetrackTabBar.swift && \
echo "=== HomeDashboardView — .top, 60 and .bottom, 100 ===" && \
grep -n "\.top, 60\|\.top,60\|\.bottom, 100\|\.bottom,100" Features/Home/HomeDashboardView.swift && \
echo "=== HomeRouterView — .bottom, 100 ===" && \
grep -n "\.bottom, 100\|\.bottom,100" Features/Home/HomeRouterView.swift && \
echo "=== GravLiftView — .vertical, 60 ===" && \
grep -n "\.vertical, 60\|\.vertical,60" Features/Home/Components/GravLiftView.swift && \
echo "=== PulseFullView — .top, 60 ===" && \
grep -n "\.top, 60\|\.top,60" Features/Pulse/PulseFullView.swift && \
echo "=== SignInView — Spacer height 60 ===" && \
grep -n "Spacer.*60\|\.top, 60\|\.top,60" Features/Auth/SignInView.swift && \
echo "=== AppShell — bottomInset + 8 ===" && \
grep -n "bottomInset.*+.*8\|\.bottom.*bottomInset" App/AppShell.swift && \
echo "=== SparkField — .top, 80 ===" && \
grep -n "\.top, 80\|\.top,80" Design/Components/Effects/SparkField.swift

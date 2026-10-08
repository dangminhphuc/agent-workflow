<!--
Mẫu AGENTS.md cho repo đích — tài liệu của engine agent-workflow, KHÔNG phải luật.
Chép vào gốc repo (cp .agent-workflow/.engine/templates/target-repo/AGENTS.md AGENTS.md),
sửa các chỗ <…>, xoá khối chú thích này, commit qua PR.

Mục đích: một phiên agent mới chỉ có repo trả lời được — hệ thống là gì, tổ chức ra sao,
chạy và kiểm thế nào, vì sao code như vậy, đang ở đâu. Câu nào không trả lời được thì
agent đoán, mỗi phiên đoán lại từ đầu.

Giữ 50–100 dòng. File này TRỎ TỚI, không chép luật: mỗi luật nằm ở đúng một chỗ (cạnh
code nó ràng buộc, hoặc trong docs/). Mục nào không áp dụng thì ghi "None", không xoá.
Claude Code đọc CLAUDE.md, không đọc AGENTS.md: tạo CLAUDE.md một dòng "@AGENTS.md".
Heading viết tiếng Anh (agent đọc lúc chạy, ít token); nội dung tiếng nào cũng được.
-->
# AGENTS.md — <tên repo>

<Một câu: repo này làm gì, cho ai.> Chi tiết sản phẩm: <docs/product/PRODUCT.md | None>.

## Map

```
<thư-mục>/        <vai trò, một dòng>
<thư-mục>/        <vai trò, một dòng>
```

Module có ràng buộc riêng giữ `ARCHITECTURE.md` ngay trong thư mục của nó:
<src/<module>/ARCHITECTURE.md, … | None>.

## Commands

Lệnh chuẩn — CI chạy đúng các lệnh này (`<đường dẫn file pipeline>`):

```sh
make setup      # <cài dependency>
make test       # <test>
make lint       # <lint, format>
make security   # <quét bảo mật, cùng ngưỡng CI>
```

## Rules

- <Ràng buộc cứng toàn repo, mỗi dòng một điều, kiểm được — vd "không gọi DB ngoài src/db/".>
- Quy ước quy trình (branch, MR, file test…): `docs/agent-workflow/conventions.md`.
- <Luật nghiệp vụ: docs/product/rules/ | None>.

## Decisions

Vì sao code như vậy: <docs/adr/ (chỉ mục: docs/adr/README.md) | None>.
Quyết định chỉ của một module: `ARCHITECTURE.md` của module đó.

## Status

<Đang làm gì, đang chặn ở đâu — hoặc chỉ tới nơi giữ: issue tracker, docs/plans/ | None>.

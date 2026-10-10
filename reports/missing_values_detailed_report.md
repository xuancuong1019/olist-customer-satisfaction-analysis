# Báo cáo phân tích chi tiết giá trị thiếu

**Dự án:** Olist E-Commerce Dataset  
**Phạm vi:** Kiểm tra missing trong dữ liệu CSV thô, tập trung vào phân tích chi tiết trong notebook `01_sanity_check_cleaning.ipynb`  
**Nguồn:** 9 bảng CSV trong `data/raw/`; đơn hàng thuộc giai đoạn 2016–2018.

## 1. Mục tiêu và cách kiểm tra

Phân tích nhằm xác định cột nào có dữ liệu thiếu, đo quy mô và tỷ lệ thiếu, sau đó kiểm tra mối liên hệ với trạng thái đơn hàng hoặc các trường liên quan để phân biệt trường hợp hợp lý theo nghiệp vụ với trường hợp cần rà soát.

Notebook đọc CSV theo từng chunk, xem `NaN` và chuỗi rỗng/space là giá trị thiếu, rồi tổng hợp số lượng và tỷ lệ thiếu theo cột. Với ngày trong bảng đơn hàng, các dòng thiếu được đối chiếu với `order_status`; riêng ngày giao cho đơn vị vận chuyển còn được kiểm tra logic với ngày giao khách hàng. Với sản phẩm thiếu metadata, phân tích lần theo `product_id` qua bảng chi tiết đơn hàng đến trạng thái đơn.

## 2. Tóm tắt kết quả

Các cột có missing tập trung ở ba nhóm: nội dung đánh giá, mốc thời gian xử lý đơn hàng và metadata sản phẩm. Các bảng khách hàng, địa lý, chi tiết đơn hàng, thanh toán, người bán và bảng dịch tên danh mục không ghi nhận missing ở các cột được kiểm tra.

| Bảng | Cột | Thiếu | Tổng dòng | Tỷ lệ |
|---|---|---:|---:|---:|
| `olist_order_reviews` | `review_comment_message` | 58.274 | 99.224 | 58,73% |
| `olist_order_reviews` | `review_comment_title` | 87.658 | 99.224 | 88,34% |
| `olist_orders` | `order_approved_at` | 160 | 99.441 | 0,16% |
| `olist_orders` | `order_delivered_carrier_date` | 1.783 | 99.441 | 1,79% |
| `olist_orders` | `order_delivered_customer_date` | 2.965 | 99.441 | 2,98% |
| `olist_products` | `product_category_name` | 610 | 32.951 | 1,85% |
| `olist_products` | `product_name_lenght` | 610 | 32.951 | 1,85% |
| `olist_products` | `product_description_lenght` | 610 | 32.951 | 1,85% |
| `olist_products` | `product_photos_qty` | 610 | 32.951 | 1,85% |
| `olist_products` | `product_weight_g`, `product_length_cm`, `product_height_cm`, `product_width_cm` | 2 mỗi cột | 32.951 | 0,01% |

Các giá trị sản phẩm được đối chiếu lại trực tiếp từ CSV. Bốn cột metadata mô tả cùng thiếu trên chính xác 610 sản phẩm; bốn thuộc tính kích thước cùng thiếu trên 2 sản phẩm.

## 3. Phân tích chi tiết

### 3.1. Ngày duyệt đơn hàng — `order_approved_at`

Có 160/99.441 đơn hàng thiếu ngày duyệt (0,16%). Phân bố trạng thái:

| Trạng thái | Số đơn |
|---|---:|
| `canceled` | 141 |
| `delivered` | 14 |
| `created` | 5 |

Phần lớn missing gắn với đơn đã hủy, phù hợp với khả năng đơn chưa hoàn tất bước duyệt. Tuy nhiên, 14 đơn `delivered` vẫn thiếu ngày duyệt; đây là nhóm không khớp kỳ vọng về trình tự nghiệp vụ và cần được xem xét riêng. Không nên điền ngày giả định cho các dòng này.

### 3.2. Ngày bàn giao cho đơn vị vận chuyển — `order_delivered_carrier_date`

Có 1.783/99.441 đơn thiếu ngày bàn giao (1,79%). Trạng thái của các đơn này:

| Trạng thái | Số đơn |
|---|---:|
| `unavailable` | 609 |
| `canceled` | 550 |
| `invoiced` | 314 |
| `processing` | 301 |
| `created` | 5 |
| `approved` | 2 |
| `delivered` | 2 |

Kiểm tra giao thoa cho thấy 1.782/1.783 đơn thiếu ngày bàn giao cũng thiếu ngày giao tới khách hàng. Một đơn còn có ngày giao khách hàng nhưng thiếu ngày bàn giao cho vận chuyển. Về trình tự thời gian, trường hợp đơn lẻ này không hợp lý và cần kiểm tra nguồn dữ liệu hoặc tính nhất quán timestamp; không nên tự suy ra ngày bàn giao.

Các trạng thái `canceled`, `unavailable`, `created`, `approved`, `processing` giải thích phần lớn trường hợp chưa có mốc bàn giao. Nhưng `invoiced` và `delivered` cần được phân tích thêm vì biểu thị các giai đoạn tiến xa hơn trong quy trình.

### 3.3. Ngày giao tới khách — `order_delivered_customer_date`

Có 2.965/99.441 đơn thiếu ngày giao khách hàng (2,98%). Phân bố trạng thái:

| Trạng thái | Số đơn |
|---|---:|
| `shipped` | 1.107 |
| `canceled` | 619 |
| `unavailable` | 609 |
| `invoiced` | 314 |
| `processing` | 301 |
| `delivered` | 8 |
| `created` | 5 |
| `approved` | 2 |

Phần lớn trường hợp thuộc đơn chưa giao xong hoặc bị hủy/không khả dụng, nên thiếu ngày giao thực tế có thể hợp lý. Có 8 đơn mang trạng thái `delivered` nhưng vẫn thiếu timestamp giao khách; đây là nhóm cần kiểm tra chất lượng dữ liệu. Trạng thái `shipped` chưa tự nó chứng minh lỗi: đơn có thể đang trên đường tại thời điểm dữ liệu ghi nhận.

### 3.4. Metadata mô tả sản phẩm

Có 610/32.951 sản phẩm (1,85%) thiếu đồng thời cả bốn trường `product_category_name`, `product_name_lenght`, `product_description_lenght`, `product_photos_qty`. Như vậy đây là một nhóm sản phẩm thiếu metadata có tính đồng thời, thay vì bốn nhóm thiếu độc lập.

Lần theo các sản phẩm này trong `olist_order_items` cho thấy chúng xuất hiện trong 1.451 đơn hàng. Phân bố trạng thái:

| Trạng thái đơn chứa sản phẩm thiếu metadata | Số đơn | Tỷ lệ trong 1.451 đơn |
|---|---:|---:|
| `delivered` | 1.392 | 95,93% |
| `shipped` | 24 | 1,65% |
| `canceled` | 14 | 0,96% |
| `processing` | 13 | 0,90% |
| `invoiced` | 8 | 0,55% |

Sản phẩm thiếu metadata vẫn xuất hiện phổ biến trong các đơn đã giao. Điều này cho thấy missing làm giảm độ đầy đủ của phân tích theo danh mục/mô tả sản phẩm, nhưng không ngăn việc ghi nhận sản phẩm trong giao dịch. Không nên xóa các đơn hoặc sản phẩm này khỏi toàn bộ phân tích; tùy mục tiêu, có thể giữ nhãn thiếu/`unknown` khi phân tích danh mục, hoặc loại khỏi các phân tích cần metadata mô tả đầy đủ.

### 3.5. Kích thước và trọng lượng sản phẩm

Các trường `product_weight_g`, `product_length_cm`, `product_height_cm`, `product_width_cm` cùng thiếu ở 2 sản phẩm (0,01% mỗi cột). Quy mô rất nhỏ, nhưng đây là thuộc tính cần thiết cho một số phân tích logistics và thể tích. Nên giữ missing trong dữ liệu nguồn sạch và xử lý theo phạm vi phân tích; nếu cần ước lượng, chỉ cân nhắc giá trị thay thế có căn cứ, chẳng hạn trung vị theo nhóm sản phẩm phù hợp.

### 3.6. Nội dung đánh giá khách hàng

`review_comment_message` thiếu 58.274/99.224 dòng (58,73%) và `review_comment_title` thiếu 87.658 dòng (88,34%). Điểm đánh giá (`review_score`) và các trường nhận diện/thời gian đánh giá không thiếu.

Việc bỏ trống nội dung và tiêu đề có thể phản ánh khách hàng chọn chấm điểm mà không viết nhận xét, nên không mặc nhiên là lỗi dữ liệu. Tỷ lệ thiếu cao làm giảm tập mẫu dùng cho phân tích văn bản hoặc cảm xúc, nhưng không cản trở phân tích điểm số. Nên giữ giá trị trống/NULL thay vì điền nội dung suy đoán; khi phân tích văn bản cần báo cáo rõ số lượng review có nội dung.

## 4. Đánh giá tác động và hướng xử lý

| Nhóm | Tác động chính | Hướng xử lý đề xuất |
|---|---|---|
| Nội dung đánh giá thiếu | Giảm số mẫu phân tích văn bản; không ảnh hưởng trực tiếp đến `review_score` | Giữ NULL; chỉ lọc khi phân tích nội dung, báo cáo mẫu khả dụng |
| Timestamp đơn hàng thiếu | Ảnh hưởng đo thời gian xử lý/giao hàng và kiểm tra SLA | Không điền ngày tùy ý; đối chiếu trạng thái, rà soát các dòng `delivered` thiếu mốc và trường hợp timestamp sai thứ tự |
| 610 sản phẩm thiếu metadata | Hạn chế phân tích danh mục và đặc điểm sản phẩm; đơn hàng vẫn có thể phân tích | Giữ sản phẩm và giao dịch; gắn nhãn thiếu khi cần tổng hợp danh mục; bổ sung từ nguồn đáng tin nếu có |
| 2 sản phẩm thiếu kích thước | Ảnh hưởng nhỏ, tập trung vào phân tích vận chuyển/kích thước | Giữ NULL; loại khỏi phép tính cần đủ kích thước hoặc impute có kiểm soát |

## 5. Điểm cần rà soát tiếp

1. Kiểm tra 14 đơn `delivered` thiếu `order_approved_at`, 2 đơn `delivered` thiếu `order_delivered_carrier_date`, và 8 đơn `delivered` thiếu `order_delivered_customer_date`.
2. Rà soát đơn duy nhất có ngày giao khách nhưng thiếu ngày bàn giao cho vận chuyển; xác nhận timestamp và định nghĩa cột từ nguồn.
3. Kiểm tra thứ tự thời gian giữa ngày mua, duyệt, bàn giao, giao khách để phát hiện lỗi logic ngoài trường hợp missing.
4. Xác định liệu có nguồn sản phẩm đáng tin cậy để bổ sung metadata cho 610 sản phẩm và thuộc tính vật lý cho 2 sản phẩm hay không.

## 6. Kết luận

Missing trong bộ dữ liệu tập trung vào các trường tùy chọn (nội dung review), các mốc thời gian chưa hoàn tất/không có giao hàng, và một nhóm sản phẩm thiếu metadata. Phần lớn trường hợp có thể được giữ nguyên như missing và xử lý theo mục tiêu phân tích. Các trường hợp cần ưu tiên kiểm tra là timestamp thiếu ở đơn `delivered` và một đơn có ngày giao khách nhưng thiếu ngày bàn giao. Nhóm 610 sản phẩm cần được giữ trong phân tích giao dịch, đồng thời đánh dấu thiếu metadata trong các phân tích sản phẩm.

**Ghi chú phương pháp:** Tỷ lệ phần trăm được tính trên tổng số dòng của từng bảng. Việc phân loại theo `order_status` giúp đánh giá tính hợp lý nghiệp vụ nhưng không đủ để khẳng định nguyên nhân gốc của từng giá trị thiếu.

## 7. Đánh giá và phương án

* order_approved_at thiếu 160 dòng (0,16%), chủ yếu là đơn hủy hoặc mới tạo. Do không đủ thông tin nghiệp vụ để xác định nguyên nhân của 14 đơn delivered bất thường, dữ liệu được giữ nguyên NULL và ghi vào data_anomalies_log. Cột này không tham gia KPI chính của đề tài nên không ảnh hưởng đến kết luận.

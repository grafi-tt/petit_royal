#!/usr/bin/ruby19
# coding: UTF-8
require 'sqlite3'
require 'nokogiri'

db = SQLite3::Database.new(ARGV[0])
$test=Hash.new

indexes = []
puts "<html>\n<head><title></title></head>\n<body>\n"
db.execute('select * from indices') {|id, id2, itemid, idx1, idx2, html|
  next if html == ""

  idxs = []
  idxs << idx1 unless idx1 == ""
  idxs << idx2 unless idx2 == ""

  if indexes[itemid]
    indexes[itemid].concat idxs
  else
    indexes[itemid] = idxs
  end
}

db.execute('select * from items') {|id, header, html, count|

  marus = %w(⓿ ➊ ➋ ➌ ➍ ➎ ➏ ➐ ➑ ➒ ➓ ⓫ ⓬ ⓭ ⓮ ⓯ ⓰ ⓱ ⓲ ⓳ ⓴)
  nums = %w(0. 1. 2. 3. 4. 5. 6. 7. 8. 9. 10. 11. 12. 13. 14. 15. 16. 17. 18. 19. 20.)
  (0..20).each{|i|html.gsub!(marus[i], nums[i])}
  tree = Nokogiri::HTML::DocumentFragment.parse html
  if id == 408
    next
  end
  if id == 2612
    tree.at_css('span.stm').content='*'
  end
  if id == 8688
    tree.css('span.tyk').last.remove
  end
  if id == 9292
    tree.css('span.stm').last.remove
  end
  if id == 16996
    tree.css('span.hse').last.remove
  end
  if id == 16996
    tree.css('span.hnk').last.remove
  end
  if id == 17024
    tree.css('span.hnk').last.remove
  end
  if id == 26416
    tree.at_css('span.kju').parent = tree.at_css('span.tyi')
  end
  if id == 29110
    tree.css('span.stm')[5].remove # 正しい記号が文字セットに無い。インライン画像で入れるべきかも。
  end
  if id == 29128
    tree.at_css('span.stm').content = ';'
  end
  tree.css('td').each{|node|node.swap node.children}
  tree.css('table').each do |table_node|
    tr_nodes = table_node.xpath('./tr')
    tr_nodes[0..-2].each{|tr_node|tr_node.add_child '<br />'} if tr_nodes.length > 1
    tr_nodes.each{|tr_node|tr_node.swap tr_node.children}
  end
  tree.css('tr').each{|node|node.add_child '<br />'; node.swap node.children}
  text = ''
  head = tree.at_css('span[class="mid"][rank]')
  content = head.xpath('following-sibling::node()')
  dd = Nokogiri::XML::Node.new('dd',tree)
  head.after dd
  next unless indexes[id]
  indexes[id].each do |idx|
    key = Nokogiri::XML::Node.new('key',tree)
    key['type'] = "表記"
    key.content = idx
    head.after key
  end
  tree.css('br').each do |br_node|
    next_node = br_node.next
    break unless next_node
    next_next_node = next_node.next
    break unless next_next_node
    br_node.remove if next_node.name == 'br' && next_next_node.name = 'br'
  end

  head.tap do |node|
    title_node = node.dup
    title_node.xpath('./sup').each{|sup_node|sup_node.swap "(#{sup_node.inner_text})"}
    title_node.xpath('./span[@class="lia"]').each{|lia_node|lia_node.remove}
    title = title_node.inner_text
    rank = node['rank'].to_i
    node['id']= id.to_s
    node.name = 'dt'
    node.xpath('./span[@class="lia"]').each{|lia_node|lia_node.swap lia_node.inner_text}
    case node['rank'].to_i
    when 13
      text = node.inner_html
    when 00, 12
      text = Nokogiri::XML::Node.new('b',tree)
      text.add_child node.children
    when 11
      text = Nokogiri::XML::Node.new('b',tree)
      text.add_child Nokogiri::XML::Text.new('* ',tree)
      text.add_child node.children
    when 10
      text = Nokogiri::XML::Node.new('b',tree)
      text.add_child Nokogiri::XML::Text.new('** ',tree)
      text.add_child node.children
    when 20
      text = Nokogiri::XML::Node.new('b',tree)
      text.add_child Nokogiri::XML::Text.new('*** ',tree)
      text.add_child node.children
    end
    node.attributes.keys.each{|key|node.delete key}
    node.add_child text
    node['title'] = title
  end

  content.each{|node|node.parent=dd}
  tree.css('a').each do |node|
    if node['onclick'] && node['onclick'] =~ /searchItem\('(\d+)','0(.*)'\)/
      jmpid, jmpname = $1, $2
      node.attributes.keys.each{|key|node.delete key}
      node['href'] = '#' + $1 + $2
    elsif node['name']
      #
    else
      node.swap node.children
    end
  end
  def_start_x4081_node = Nokogiri::XML::Node.new('X4081',tree)
  def_start_x4081_node.content = '1F09 0002'
  dd.at_xpath('br').after def_start_x4081_node
  tree.css('table[id^="block"]').each do |node|
    prev_node = node.previous_sibling
    if prev_node.name = 'br'
      para_start_node = prev_node
    else
      para_start_node = node.xpath('.//br').first
    end
    para_end_node = node.children.last
    #node.after Nokogiri::XML::Node.new('br',tree)
    node.swap node.children

    para_start_x4081_node = Nokogiri::XML::Node.new('X4081',tree)
    para_start_x4081_node.content = '1F09 0003'
    para_start_node.after para_start_x4081_node
    para_end_x4081_node = Nokogiri::XML::Node.new('X4081',tree)
    para_end_x4081_node.content = '1F09 0002'
    para_end_node.after para_end_x4081_node
  end

  tree.css('span').each do |node|
    case node['class']
    when 'hns', 'maru', 'kkm', 'vbn', 'logo'
      node.children.before '['
      node.children.after ']'
      content = node.children
    when 'dbn'
      node.children.before '['
      node.children.after ']'
      content = Nokogiri::XML::Node.new('b',tree)
      content.add_child node.children
    when 'yri'
      dummy = Nokogiri::XML::Node.new('dummy',tree)
      dfn = Nokogiri::XML::Node.new('dfn',tree)
      dfn.add_child(node.children)
      dummy.add_child dfn
      dummy.add_child Nokogiri::XML::Text.new(' ', tree)
      content = dummy.children
    when 'sku'
      dummy = Nokogiri::XML::Node.new('dummy',tree)
      dfn = Nokogiri::XML::Node.new('dfn',tree)
      dfn.add_child Nokogiri::XML::Node.new('b',tree)
      dfn.add_child node.children
      dummy.add_child dfn
      dummy.add_child Nokogiri::XML::Text.new(' ', tree)
      content = dummy.children
    when 'gnk', 'dim', 'kri'
      content = Nokogiri::XML::Node.new('b',tree)
      content.add_child node.children
    when 'mid' #FIXME
      content = Nokogiri::XML::Node.new('b',tree)
      content.add_child node.children
    when 'ykg', 'yry', 'sky', 'kby', 'kwa', 'kwy', 'msy'
      content = node.children
    when 'eng', 'hgo', 'henk', 'dou'
      node.children.before '（'
      node.children.after '）'
      content = node.children
    when 'doi'
      node.children.before '（＝'
      node.children.after '）'
      content = node.children
    when 'ggn'
      node.children.before '（＜'
      node.children.after '）'
      content = node.children
    when 'hai'
      node.children.before '（⇔'
      node.children.after '）'
      content = node.children
    when 'hse', 'gng'
      node.children.before '（←'
      node.children.after '）'
      content = node.children
    when 'tyk'
      node.children.before '（◆'
      node.children.after '）'
      content = node.children
    when 'bnk'
      node.children.before '（過分：'
      node.children.after '）'
      content = node.children
    when 'jds'
      node.children.before '（助動：'
      node.children.after '）'
      content = node.children
    when 'ryk'
      node.children.before '（略：'
      node.children.after '）'
      content = node.children
    when 'okr'
      node.children.before '＝'
      content = node.children
    when 'gos', 'stm', 'gok', 'gnt', 'hoj', 'bns', 'zhk'
      node.children.before ' (( '
      node.children.after ' )) '
      content = node.children
    when 'bny'
      node.children.before '【'
      node.children.after '】'
      content = node.children
    when 'kbn'
      node.children.before '【'
      node.children.after '】'
      content = Nokogiri::XML::Node.new('b',tree)
      content.add_child node.children
    when 'dbg'
      node.children.before '［'
      node.children.after '］'
      content = node.children
    when 'phn'
      node.children.before '/ '
      node.children.after '/'
      content = node.children
    when 'has'
      node.children.before '◇'
      content = node.children
    when 'maru_b'
      node.children.after '.'
      content = node.children
    when 'ggi', 'skb'
      node.children.after ' '
      content = node.children
    when 'msb'
      node.children.after '    '
      content = node.children
    when 'kgu', 'skan', 'kju', 'nami', 'bet'
      content = node.children
    when 'rsm', 'rsme', 'kakomi', 'snk'
      content = ''

    when 'blockmark'
      prev_node = node.previous_sibling
      if prev_node.name=='table' || prev_node.name=='br'
        next_node = node.next_sibling
        next_next_node = next_node.next_sibling
        if next_node.name = 'br'
          next_node.remove
        end
      end
      next_node = node.next_sibling
      if next_node.name = 'br'
        next_node.remove
      end
      content = ''
    when 'rubi'
      ruby_node = Nokogiri::XML::Node.new('ruby',tree)
      ruby_node.add_child Nokogiri::XML::Node.new('rb',tree)
      rt_node = Nokogiri::XML::Node.new('rt',tree)
      rt_node.add_child node.children
      content = ruby_node
    when 'pnt'
      content = '[ポイント] '
    when 'kji'
      content = '会話をつなぐ'
    when 'logo_c'
      content = '[参考] '
    when 'rui'
      node.children.before '[類語] '
      content = node.children
    when 'tyi'
      node.children.before '[注意] '
      content = node.children
    when 'knr'
      node.children.before '[関連] '
      content = node.children
    when 'hnk'
      content = '── '
    when 'kyo'
      content = node.children # ː
    when 'sny'
      node.children.before '⇒ '
      content = node.children
    when 'hat'
      if node['pf']=='/'
        node.children.before('  /')
        content = node.children
      end
      if node['sf']=='/'
        node.children.after('/  ')
        content = node.children
      end
    when 'hak'
      if node['sf']=='/'
        node.children.before(' ')
        node.children.after('/  ')
        content = node.children
      end
    else
      if node['pf']=='start' || node['sf']=='end'
        content = node.children
      else
        raise
      end
    end
    node.swap content
  end
  puts tree.to_html(encoding: 'Shift_JIS')
}
puts "</body>\n</html>"
